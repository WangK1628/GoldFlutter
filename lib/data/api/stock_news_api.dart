import 'api_client.dart';

class StockNewsItem {
  const StockNewsItem({
    required this.title,
    required this.time,
    this.summary = '',
    this.url = '',
  });

  final String title;
  final String time;
  final String summary;
  final String url;
}

class StockNewsApi {
  StockNewsApi(this._client);
  final ApiClient _client;

  static const _referer = 'https://finance.eastmoney.com/';

  Future<List<StockNewsItem>> fetchNews(String code, {String name = ''}) async {
    final items = <StockNewsItem>[];
    try {
      items.addAll(await _fromEastMoney(code));
    } catch (_) {}
    if (items.isEmpty) {
      try {
        items.addAll(await _fromAnnouncements(code));
      } catch (_) {}
    }
    if (items.isEmpty && name.isNotEmpty) {
      try {
        items.addAll(await _fromSearch(name));
      } catch (_) {}
    }
    return items;
  }

  String _emCode(String code) {
    final c = code.toLowerCase();
    if (c.startsWith('sh')) return 'SH${c.substring(2).toUpperCase()}';
    if (c.startsWith('sz')) return 'SZ${c.substring(2).toUpperCase()}';
    return c.toUpperCase();
  }

  String _digits(String code) {
    final m = RegExp(r'\d+').firstMatch(code);
    return m?.group(0) ?? code;
  }

  Future<List<StockNewsItem>> _fromEastMoney(String code) async {
    final em = _emCode(code);
    final url =
        'https://emweb.securities.eastmoney.com/PC_HSF10/NewsBulletin/PageAjax?code=$em&page=1&pageSize=15';
    final json = await _client.getJson(url, headers: {'Referer': _referer});

    final items = <StockNewsItem>[];

    final gszx = json['gszx'] as Map<String, dynamic>?;
    final data = gszx?['data'] as Map<String, dynamic>?;
    final newsList = data?['items'] as List<dynamic>? ?? [];
    for (final e in newsList) {
      final m = e as Map<String, dynamic>;
      items.add(StockNewsItem(
        title: (m['title'] ?? '').toString(),
        time: _formatMs(m['showDateTime']),
        summary: (m['summary'] ?? '').toString(),
        url: (m['url'] ?? m['uniqueUrl'] ?? '').toString(),
      ));
    }

    final gsgg = json['gsgg'] as List<dynamic>? ?? [];
    for (final e in gsgg) {
      final m = e as Map<String, dynamic>;
      final title = (m['title'] ?? '').toString();
      if (title.isEmpty) continue;
      if (items.any((i) => i.title == title)) continue;
      items.add(StockNewsItem(
        title: title,
        time: (m['notice_date'] ?? m['display_time'] ?? '').toString(),
        summary: '公司公告',
        url: '',
      ));
    }

    return items.where((e) => e.title.isNotEmpty).toList();
  }

  Future<List<StockNewsItem>> _fromAnnouncements(String code) async {
    final digits = _digits(code);
    final url =
        'https://np-anotice-stock.eastmoney.com/api/security/ann?sr=-1&page_size=12&page_index=1&ann_type=A&client_source=web&stock_list=$digits';
    final json = await _client.getJson(url);
    final list = (json['data'] as Map<String, dynamic>?)?['list'] as List<dynamic>? ?? [];
    return list.map((e) {
      final m = e as Map<String, dynamic>;
      return StockNewsItem(
        title: (m['title'] ?? m['title_ch'] ?? '').toString(),
        time: (m['notice_date'] ?? m['display_time'] ?? '').toString(),
        summary: '公司公告',
        url: '',
      );
    }).where((e) => e.title.isNotEmpty).toList();
  }

  Future<List<StockNewsItem>> _fromSearch(String keyword) async {
    final param =
        '{"uid":"","keyword":"$keyword","type":["cmsArticleWebOld"],"client":"web","clientType":"web","clientVersion":"1.0.0","pageIndex":1,"pageSize":12}';
    final url = 'https://search-api-web.eastmoney.com/search/jsonp?param=${Uri.encodeComponent(param)}';
    final text = await _client.getText(url, headers: {'Referer': _referer});
    final titles = RegExp(r'"title":"([^"\\]+)"')
        .allMatches(text)
        .map((m) => m.group(1) ?? '')
        .where((t) => t.isNotEmpty);
    return titles.take(10).map((t) => StockNewsItem(title: t, time: '')).toList();
  }

  String _formatMs(dynamic raw) {
    if (raw == null) return '';
    final ms = raw is int ? raw : int.tryParse(raw.toString()) ?? 0;
    if (ms <= 0) return '';
    final dt = DateTime.fromMillisecondsSinceEpoch(ms);
    final mm = dt.month.toString().padLeft(2, '0');
    final dd = dt.day.toString().padLeft(2, '0');
    final hh = dt.hour.toString().padLeft(2, '0');
    final mi = dt.minute.toString().padLeft(2, '0');
    return '${dt.year}-$mm-$dd $hh:$mi';
  }
}
