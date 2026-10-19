import 'package:flutter_test/flutter_test.dart';
import 'package:lcg/data/parser/articles_parser.dart';
import 'package:lcg/data/parser/doc_parser.dart';

void main() {
  group('ArticlesParser', () {
    test('解析首页文章列表（tbody[id^=normal]）', () {
      const html = '''
<html><body>
<table>
  <tbody id="normal_123">
    <tr>
      <td class="num"><a class="xi2">12</a><em>345</em></td>
      <th class="common"><a class="xst" href="thread-1-1-1.html">测试标题A</a></th>
      <td class="by"><a href="space-uid-1.html" target="_blank">作者A</a><span>2020-01-02 03:04</span></td>
    </tr>
  </tbody>
  <tbody id="normal_456">
    <tr>
      <td class="num"><a class="xi2">3</a><em>99</em></td>
      <th class="common"><a class="xst" href="thread-2-1-1.html">测试标题B</a></th>
      <td class="by"><a href="space-uid-2.html" target="_blank">作者B</a><span>2020-02-02 03:04</span></td>
    </tr>
  </tbody>
</table>
</body></html>''';
      final list = ArticlesParser.parseHomeArticles(html);
      expect(list.length, 2);
      expect(list[0].title, '测试标题A');
      expect(list[0].author, '作者A');
      expect(list[0].reply, 12);
      expect(list[0].view, 345);
      expect(list[0].fullUrl, 'https://www.52pojie.cn/thread-1-1-1.html');
      expect(list[1].title, '测试标题B');
    });

    test('详情解析：标题/作者/内容清理', () {
      const html = '''
<html><body>
<span id="thread_subject">详情标题</span>
<div class="pcb">
  <table>
    <tr>
      <td rowspan="1">
        <div class="avatar"><img src="a.png"><a href="space-uid-9.html"></a></div>
        <a class="xw1">楼猪</a>
      </td>
      <td class="t_f">
        <div class="tip">不要看</div>
        <script>bad()</script>
        <p>正文内容</p>
        <pre>code line1\ncode line2</pre>
        <img src="https://static.52pojie.cn/static/placeholder.png">
        <img src="tiny.png" file="https://img.example.com/real.png">
      </td>
    </tr>
  </table>
</div>
<div class="authi"><em>2020-05-06 07:08</em></div>
</body></html>''';
      final detail = ArticlesParser.parseArticleDetail(html);
      expect(detail.title, '详情标题');
      expect(detail.posts.length, 1);
      final post = detail.posts.first;
      expect(post.author, '楼猪');
      expect(post.date, '2020-05-06 07:08');
      expect(post.content.contains('正文内容'), isTrue);
      // tip 与 script 被移除
      expect(post.content.contains('不要看'), isFalse);
      expect(post.content.contains('bad()'), isFalse);
      // pre 换行转 <br>（html 包序列化为 <br> 而非 <br/>）
      expect(post.content.contains('<br'), isTrue);
      // 静态占位图被移除，file 属性提升为 src
      expect(post.content.contains('static/placeholder'), isFalse);
      expect(post.content.contains('https://img.example.com/real.png'), isTrue);
    });
  });

  group('DocParser', () {
    test('解析用户信息', () {
      const html = '''
<html><body>
<h2 class="mt">测试用户</h2>
<div class="avt"><a><img src="avatar.png"></a></div>
<div id="g_upmine">论坛元老</div>
<div id="psts"><ul class="pf_l">
  <li><em>A</em></li><li><em>积分:100</em></li><li><em>C</em></li>
  <li><em>吾爱币:50</em></li><li><em>E</em></li><li><em>F</em></li>
  <li><em>采纳率:10%</em></li><li><em>热心值:5</em></li>
</ul></div>
</body></html>''';
      final info = DocParser.parseUserInfo(html);
      expect(info.userName, '测试用户');
      expect(info.avatarUrl, 'avatar.png');
      expect(info.groupInfo, '论坛元老');
      expect(info.wuaiCoin, contains('50'));
      expect(info.credit, contains('100'));
    });

    test('未登录时返回默认用户', () {
      const html = '<html><body><h2 class="mt">登录或注册</h2></body></html>';
      final info = DocParser.parseUserInfo(html);
      expect(info.userName, '游客');
    });
  });
}
