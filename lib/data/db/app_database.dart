import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../../core/config/website_constants.dart';
import '../../core/network/api_client.dart';
import '../models/article.dart';
import '../parser/articles_parser.dart';

/// 本地数据库 —— 对应原生 Room articles.db，含阅读历史与本地收藏
class AppDatabase {
  AppDatabase._();

  static Database? _db;

  static Future<Database> get instance async {
    if (_db != null) return _db!;
    final path = join(await getDatabasesPath(), 'articles.db');
    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE history(
            url TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            author TEXT NOT NULL DEFAULT '',
            content TEXT NOT NULL DEFAULT '',
            timestamp INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE favorite(
            url TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            timestamp INTEGER NOT NULL
          )
        ''');
      },
    );
    return _db!;
  }
}

/// 阅读历史仓库（替代 Room HistoryDao）
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

/// 本地收藏仓库（对应 FavoriteDataSource 本地部分 + FavoriteArticlesViewModel）
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

/// 在线收藏仓库（对应 FavoriteDataSource.getAllRemoteFavorites + 删除）
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
      // 对应原生删除接口：返回 ajax 成功标记
      return !(doc.documentElement?.outerHtml.contains('error') ?? true);
    } catch (_) {
      return false;
    }
  }
}