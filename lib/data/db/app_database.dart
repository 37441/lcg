import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../../core/config/website_constants.dart';
import '../../core/network/api_client.dart';
import '../models/article.dart';
import '../parser/articles_parser.dart';

/// 本地数据库 —— 阅读历史与本地收藏
class AppDatabase {
  AppDatabase._();

  static Database? _db;

  static const _createHistory = '''
    CREATE TABLE history(
      url TEXT PRIMARY KEY,
      title TEXT NOT NULL,
      author TEXT NOT NULL DEFAULT '',
      content TEXT NOT NULL DEFAULT '',
      timestamp INTEGER NOT NULL
    )
  ''';

  static const _createFavorite = '''
    CREATE TABLE favorite(
      url TEXT PRIMARY KEY,
      title TEXT NOT NULL,
      timestamp INTEGER NOT NULL
    )
  ''';

  static Future<Database> get instance async {
    if (_db != null) return _db!;
    final path = join(await getDatabasesPath(), 'articles.db');
    _db = await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute(_createHistory);
        await db.execute(_createFavorite);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        // 旧版本表结构不兼容（存在非空 id 列），重建表
        await db.execute('DROP TABLE IF EXISTS history');
        await db.execute('DROP TABLE IF EXISTS favorite');
        await db.execute(_createHistory);
        await db.execute(_createFavorite);
      },
    );
    return _db!;
  }
}

/// 阅读历史仓库
class HistoryRepository {
  HistoryRepository._();

  static final HistoryRepository instance = HistoryRepository._();

  Future<void> addHistory({
    required String url,
    required String title,
    required String author,
    String content = '',
  }) async {
    final db = await AppDatabase.instance;
    await db.insert(
      'history',
      {
        'url': url,
        'title': title,
        'author': author,
        'content': content,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<ArticleEntity>> getAll() async {
    final db = await AppDatabase.instance;
    final rows = await db.query('history', orderBy: 'timestamp DESC');
    return rows
        .map((r) => ArticleEntity(
              title: r['title'] as String? ?? '',
              author: r['author'] as String? ?? '',
              url: r['url'] as String? ?? '',
              content: r['content'] as String? ?? '',
              timestamp: r['timestamp'] as int? ?? 0,
            ))
        .toList();
  }

  Future<void> clear() async {
    final db = await AppDatabase.instance;
    await db.delete('history');
  }
}

/// 本地收藏仓库
class FavoriteLocalRepository {
  FavoriteLocalRepository._();

  static final FavoriteLocalRepository instance = FavoriteLocalRepository._();

  Future<List<ArticleEntity>> getAll() async {
    final db = await AppDatabase.instance;
    final rows = await db.query('favorite', orderBy: 'timestamp DESC');
    return rows
        .map((r) => ArticleEntity(
              title: r['title'] as String? ?? '',
              url: r['url'] as String? ?? '',
              timestamp: r['timestamp'] as int? ?? 0,
            ))
        .toList();
  }

  Future<bool> add(ArticleEntity entity) async {
    final db = await AppDatabase.instance;
    await db.insert(
      'favorite',
      {
        'url': entity.url,
        'title': entity.title,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return true;
  }

  Future<void> remove(String url) async {
    final db = await AppDatabase.instance;
    await db.delete('favorite', where: 'url = ?', whereArgs: [url]);
  }

  Future<void> clearAll() async {
    final db = await AppDatabase.instance;
    await db.delete('favorite');
  }
}

/// 在线收藏仓库
class FavoriteRemoteRepository {
  FavoriteRemoteRepository._();

  static final FavoriteRemoteRepository instance = FavoriteRemoteRepository._();

  final _api = ApiClient.instance;

  Future<List<ArticleEntity>> getAllRemote() async {
    final list = <ArticleEntity>[];
    String? nextPageUrl = WebsiteConstants.getFavoriteQuery;
    while (nextPageUrl != null) {
      final doc = await _api.getWithQuery(nextPageUrl);
      list.addAll(ArticlesParser.parseFavorites(doc.documentElement!.outerHtml));
      nextPageUrl = doc.querySelector('a.nxt')?.attributes['href'];
    }
    return list;
  }

  Future<bool> removeRemote(String delUrl) async {
    try {
      final doc = await _api.getWithQuery(delUrl);
      return !(doc.documentElement?.outerHtml.contains('error') ?? true);
    } catch (_) {
      return false;
    }
  }
}