import '../../models/market_models.dart';

enum StockMarket { cn, hk, us }

class StockParseResult {
  const StockParseResult({
    required this.symbol,
    required this.market,
    this.label = '',
    this.error = '',
  });

  final String symbol;
  final StockMarket market;
  final String label;
  final String error;

  bool get ok => error.isEmpty && symbol.isNotEmpty;
}

/// 兼容旧调用。
String? normalizeStockCode(String raw) {
  final r = parseStockInput(raw);
  return r.ok ? r.symbol : null;
}

StockParseResult parseStockInput(String raw) {
  var s = raw.trim();
  if (s.isEmpty) return const StockParseResult(symbol: '', market: StockMarket.cn, error: '请输入代码');

  final preset = _presetByName[s];
  if (preset != null) return preset;

  s = s.toLowerCase().replaceAll(RegExp(r'[\s\.\-]'), '');

  if (RegExp(r'^(sh|sz|bj)\d{6}$').hasMatch(s)) {
    return StockParseResult(symbol: s, market: StockMarket.cn);
  }
  if (RegExp(r'^hk[a-z0-9]{3,8}$').hasMatch(s)) {
    return StockParseResult(symbol: s, market: StockMarket.hk);
  }
  if (RegExp(r'^gb_[a-z0-9_]+$').hasMatch(s)) {
    return StockParseResult(symbol: s, market: StockMarket.us);
  }
  if (RegExp(r'^\d{6}$').hasMatch(s)) {
    final cn = _cnFromDigits(s);
    if (cn == null) {
      return const StockParseResult(symbol: '', market: StockMarket.cn, error: 'A股代码无效');
    }
    return StockParseResult(symbol: cn, market: StockMarket.cn);
  }
  if (RegExp(r'^\d{5}$').hasMatch(s)) {
    return StockParseResult(symbol: 'hk$s', market: StockMarket.hk);
  }
  if (RegExp(r'^[a-z]{1,6}$').hasMatch(s)) {
    return StockParseResult(symbol: 'gb_$s', market: StockMarket.us);
  }
  return const StockParseResult(
    symbol: '',
    market: StockMarket.cn,
    error: '格式无效，示例：600519 / 00700 / AAPL',
  );
}

String? _cnFromDigits(String s) {
  if (s[0] == '6' || s.startsWith('90') || s[0] == '5') return 'sh$s';
  if ('0321'.contains(s[0])) return 'sz$s';
  if ('84'.contains(s[0]) || s.startsWith('92')) return 'bj$s';
  return null;
}

String marketTag(StockMarket m) => switch (m) {
      StockMarket.cn => 'A',
      StockMarket.hk => '港',
      StockMarket.us => '美',
    };

StockMarket marketOfCode(String code) {
  final c = code.toLowerCase();
  if (c.startsWith('hk')) return StockMarket.hk;
  if (c.startsWith('gb_')) return StockMarket.us;
  return StockMarket.cn;
}

String sessionHint([String? code]) {
  if (code != null && code.isNotEmpty) {
    return marketSessionHint(marketOfCode(code));
  }
  return marketSessionHint(StockMarket.cn);
}

String marketSessionHint(StockMarket market) {
  final now = DateTime.now();
  if (market == StockMarket.cn) return _cnSession(now);
  if (market == StockMarket.hk) return _hkSession(now);
  return _usSession(now);
}

String _cnSession(DateTime now) {
  if (now.weekday >= 6) return 'A股休市';
  final t = now.hour * 100 + now.minute;
  if (t >= 930 && t <= 1130 || t >= 1300 && t <= 1500) return 'A股交易中';
  if (t >= 915 && t < 930) return 'A股集合竞价';
  return 'A股已收盘';
}

String _hkSession(DateTime now) {
  if (now.weekday >= 6) return '港股休市';
  final t = now.hour * 100 + now.minute;
  if (t >= 930 && t <= 1200 || t >= 1300 && t <= 1600) return '港股交易中';
  return '港股已收盘';
}

String _usSession(DateTime now) {
  // 美东约 9:30–16:00 → 北京冬令时 22:30–05:00，夏令时 21:30–04:00（简化）
  final h = now.hour;
  if (now.weekday == 6) return '美股休市';
  if (now.weekday == 7) return '美股休市';
  if (h >= 21 || h < 5) return '美股交易中';
  if (h >= 5 && h < 9) return '美股盘后';
  return '美股盘前/休市';
}

class StockPreset {
  const StockPreset({required this.symbol, required this.name, required this.category});

  final String symbol;
  final String name;
  final String category;
}

const stockPresets = <StockPreset>[
  // A股指数
  StockPreset(symbol: 'sh000001', name: '上证指数', category: 'A股指数'),
  StockPreset(symbol: 'sz399001', name: '深证成指', category: 'A股指数'),
  StockPreset(symbol: 'sz399006', name: '创业板指', category: 'A股指数'),
  StockPreset(symbol: 'sh000300', name: '沪深300', category: 'A股指数'),
  StockPreset(symbol: 'sh000016', name: '上证50', category: 'A股指数'),
  StockPreset(symbol: 'sh000905', name: '中证500', category: 'A股指数'),
  // A股热门
  StockPreset(symbol: 'sh600519', name: '贵州茅台', category: 'A股'),
  StockPreset(symbol: 'sz300750', name: '宁德时代', category: 'A股'),
  StockPreset(symbol: 'sh601318', name: '中国平安', category: 'A股'),
  // ETF
  StockPreset(symbol: 'sh510300', name: '沪深300ETF', category: 'ETF'),
  StockPreset(symbol: 'sh510500', name: '中证500ETF', category: 'ETF'),
  StockPreset(symbol: 'sz159915', name: '创业板ETF', category: 'ETF'),
  StockPreset(symbol: 'sh518880', name: '黄金ETF', category: 'ETF'),
  // 港股
  StockPreset(symbol: 'hkHSI', name: '恒生指数', category: '港股指数'),
  StockPreset(symbol: 'hkHSCEI', name: '恒生国企', category: '港股指数'),
  StockPreset(symbol: 'hk00700', name: '腾讯控股', category: '港股'),
  StockPreset(symbol: 'hk09988', name: '阿里巴巴', category: '港股'),
  StockPreset(symbol: 'hk01810', name: '小米集团', category: '港股'),
  // 美股
  StockPreset(symbol: 'gb_dji', name: '道琼斯', category: '美股指数'),
  StockPreset(symbol: 'gb_ixic', name: '纳斯达克', category: '美股指数'),
  StockPreset(symbol: 'gb_inx', name: '标普500', category: '美股指数'),
  StockPreset(symbol: 'gb_aapl', name: '苹果', category: '美股'),
  StockPreset(symbol: 'gb_tsla', name: '特斯拉', category: '美股'),
  StockPreset(symbol: 'gb_nvda', name: '英伟达', category: '美股'),
];

final _presetByName = <String, StockParseResult>{
  for (final p in stockPresets)
    p.name: StockParseResult(
      symbol: p.symbol,
      market: marketOfCode(p.symbol),
      label: p.name,
    ),
};

List<String> stockPresetCategories() {
  final seen = <String>{};
  final out = <String>[];
  for (final p in stockPresets) {
    if (seen.add(p.category)) out.add(p.category);
  }
  return out;
}

/// 从行情行取可读名称。
String stockRowName(StockRow row) =>
    resolveStockName(row.meta.code, row.cells.length > 1 ? row.cells[1] : '');

String resolveStockName(String code, String rawName) {
  final cleaned = rawName.trim();
  if (_isReadableName(cleaned)) return cleaned;
  for (final p in stockPresets) {
    if (p.symbol.toLowerCase() == code.toLowerCase()) return p.name;
  }
  if (code.startsWith('gb_')) return code.substring(3).toUpperCase();
  if (code.startsWith('hk')) {
    final tail = code.substring(2);
    return tail.toUpperCase();
  }
  if (code.length > 2 && RegExp(r'^(sh|sz|bj)').hasMatch(code)) {
    return code.substring(2);
  }
  return code;
}

bool _isReadableName(String s) {
  if (s.isEmpty || s == '-') return false;
  if (s.contains('\uFFFD')) return false;
  if (RegExp(r'^[?\s]+$').hasMatch(s)) return false;
  if (RegExp(r'[ÃÂÐÑ¤]').hasMatch(s) && !RegExp(r'[\u4e00-\u9fff]').hasMatch(s)) {
    return false;
  }
  return true;
}
