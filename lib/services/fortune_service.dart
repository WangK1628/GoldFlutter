import 'dart:math';

import '../models/market_models.dart';
import '../utils/stock_code.dart';

/// 财神签 — 根据金价、自选与用户所求生成趣味签文。
class FortuneStick {
  const FortuneStick({
    required this.level,
    required this.title,
    required this.poem,
    required this.advice,
    required this.luckyStock,
    required this.luckyAction,
    required this.moodEmoji,
    this.wish = '',
    this.stockInsight = '',
  });

  final String level;
  final String title;
  final String poem;
  final String advice;
  final String luckyStock;
  final String luckyAction;
  final String moodEmoji;
  final String wish;
  final String stockInsight;

  Map<String, dynamic> toJson() => {
        'level': level,
        'title': title,
        'poem': poem,
        'advice': advice,
        'luckyStock': luckyStock,
        'luckyAction': luckyAction,
        'moodEmoji': moodEmoji,
        'wish': wish,
        'stockInsight': stockInsight,
      };

  factory FortuneStick.fromJson(Map<String, dynamic> j) => FortuneStick(
        level: j['level'] as String? ?? '中签',
        title: j['title'] as String? ?? '',
        poem: j['poem'] as String? ?? '',
        advice: j['advice'] as String? ?? '',
        luckyStock: j['luckyStock'] as String? ?? '',
        luckyAction: j['luckyAction'] as String? ?? '',
        moodEmoji: j['moodEmoji'] as String? ?? '🍵',
        wish: j['wish'] as String? ?? '',
        stockInsight: j['stockInsight'] as String? ?? '',
      );
}

class FortuneService {
  static const levels = ['下下签', '下签', '中下签', '中签', '中上签', '上签', '上上签'];

  static int _previewNonce = 0;

  static FortuneStick draw({
    required MarketSnapshot gold,
    required StockBoard stocks,
    required String sentence,
    String wish = '',
    int? salt,
    bool preview = false,
  }) {
    final nonce = preview ? ++_previewNonce : 0;
    final seed = Object.hash(
      salt ?? DateTime.now().microsecondsSinceEpoch,
      nonce,
      wish,
      gold.cnyPrice.toStringAsFixed(2),
    );
    final rng = Random(seed);

    // 七种签级等概率随机，行情仅作签文润色
    final level = levels[rng.nextInt(levels.length)];
    final session = sessionHint();
    final pct = gold.dayChangePct;
    final up = stocks.rows.where((r) => r.meta.delta > 0).length;
    final down = stocks.rows.where((r) => r.meta.delta < 0).length;
    final flat = stocks.rows.length - up - down;

    final pool = _poems[level]!;
    var poem = pool[rng.nextInt(pool.length)];
    if (wish.isNotEmpty) {
      poem = '所求：「$wish」\n$poem';
    } else if (sentence.isNotEmpty && rng.nextBool()) {
      poem = '「$sentence」\n$poem';
    }

    final stockInsight = _buildStockInsight(wish, stocks);
    final pick = _pickLuckyStock(stocks, wish, rng);
    final luckyName = pick != null && pick.cells.length > 1 ? pick.cells[1] : '黄金';

    final actions = _actions[level]!;
    final action = actions[rng.nextInt(actions.length)];

    return FortuneStick(
      level: level,
      title: _titles[level]!,
      poem: poem,
      advice: _advice(level, pct, session, up, down, flat, stocks.rows.isNotEmpty, wish),
      luckyStock: luckyName,
      luckyAction: action,
      moodEmoji: _emoji[level]!,
      wish: wish,
      stockInsight: stockInsight,
    );
  }

  /// 再求一签：保留签级/标题，仅刷新下方文案。
  static FortuneStick redrawContent({
    required FortuneStick base,
    required MarketSnapshot gold,
    required StockBoard stocks,
    required String sentence,
  }) {
    final nonce = ++_previewNonce;
    final rng = Random(Object.hash(nonce, DateTime.now().microsecondsSinceEpoch, base.level));
    final level = base.level;
    final wish = base.wish;
    final session = sessionHint();
    final pct = gold.dayChangePct;
    final up = stocks.rows.where((r) => r.meta.delta > 0).length;
    final down = stocks.rows.where((r) => r.meta.delta < 0).length;
    final flat = stocks.rows.length - up - down;

    final pool = _poems[level] ?? _poems['中签']!;
    var poem = pool[rng.nextInt(pool.length)];
    if (wish.isNotEmpty) {
      poem = '所求：「$wish」\n$poem';
    } else if (sentence.isNotEmpty && rng.nextBool()) {
      poem = '「$sentence」\n$poem';
    }

    final stockInsight = _buildStockInsight(wish, stocks);
    final pick = _pickLuckyStock(stocks, wish, rng);
    final luckyName = pick != null && pick.cells.length > 1 ? pick.cells[1] : '黄金';
    final actions = _actions[level] ?? _actions['中签']!;
    final action = actions[rng.nextInt(actions.length)];

    return FortuneStick(
      level: base.level,
      title: base.title,
      poem: poem,
      advice: _advice(level, pct, session, up, down, flat, stocks.rows.isNotEmpty, wish),
      luckyStock: luckyName,
      luckyAction: action,
      moodEmoji: base.moodEmoji,
      wish: wish,
      stockInsight: stockInsight,
    );
  }

  static StockRow? _pickLuckyStock(StockBoard stocks, String wish, Random rng) {
    if (stocks.rows.isEmpty) return null;
    final matched = _matchWishStocks(wish, stocks);
    if (matched.isNotEmpty) return matched[rng.nextInt(matched.length)];
    return stocks.rows[rng.nextInt(stocks.rows.length)];
  }

  static List<StockRow> _matchWishStocks(String wish, StockBoard board) {
    if (wish.trim().isEmpty || board.rows.isEmpty) return [];
    final w = wish.trim();
    final nameI = board.headers.indexOf('名称');
    final codeI = board.headers.indexOf('代码');
    final seen = <String>{};
    final out = <StockRow>[];
    for (final row in board.rows) {
      final code = row.meta.code.isNotEmpty
          ? row.meta.code
          : (codeI >= 0 && codeI < row.cells.length ? row.cells[codeI] : '');
      final name = nameI >= 0 && nameI < row.cells.length ? row.cells[nameI] : '';
      final key = code.isNotEmpty ? code : name;
      if (key.isEmpty || seen.contains(key)) continue;

      var hit = false;
      if (name.length >= 2 && w.contains(name)) hit = true;
      if (!hit && code.isNotEmpty) {
        final digits = code.replaceAll(RegExp(r'[^0-9]'), '');
        if (digits.length >= 4 && w.contains(digits)) hit = true;
        final norm = normalizeStockCode(code);
        if (norm != null && w.toLowerCase().contains(norm)) hit = true;
      }
      if (hit) {
        seen.add(key);
        out.add(row);
      }
    }
    return out;
  }

  static String _buildStockInsight(String wish, StockBoard board) {
    final rows = _matchWishStocks(wish, board);
    if (rows.isEmpty) return '';
    final nameI = board.headers.indexOf('名称');
    final priceI = board.headers.indexOf('现价');
    final pctI = board.headers.indexOf('涨跌幅');
    final parts = <String>[];
    for (final row in rows.take(3)) {
      final name = nameI >= 0 && nameI < row.cells.length ? row.cells[nameI] : row.meta.code;
      final price = priceI >= 0 && priceI < row.cells.length ? row.cells[priceI] : '--';
      final pct = pctI >= 0 && pctI < row.cells.length ? row.cells[pctI] : '';
      final k = row.kline;
      final trend = _klineTrend(k);
      final volHint = _volumeHint(row.meta.commi);
      final counsel = _stockCounsel(pct, trend, k);
      parts.add('【$name】现价 $price（$pct），日K$trend，$volHint。$counsel');
    }
    return parts.join('\n');
  }

  static String _klineTrend(StockKlineData? k) {
    if (k == null) return '走势待观察';
    final body = (k.close - k.open).abs();
    final range = (k.high - k.low).abs();
    if (range <= 0) return '窄幅整理';
    final ratio = body / range;
    if (k.close > k.open * 1.008) return ratio > 0.55 ? '阳线实体偏强' : '上影试探';
    if (k.close < k.open * 0.992) return ratio > 0.55 ? '阴线承压' : '下影有支撑';
    return '十字星震荡';
  }

  static String _volumeHint(int commi) {
    if (commi >= 30) return '委比偏多';
    if (commi <= -30) return '委比偏空';
    return '多空均衡';
  }

  static String _stockCounsel(String pct, String trend, StockKlineData? k) {
    final p = pct.trim();
    if (p.startsWith('+') && (double.tryParse(p.replaceAll(RegExp(r'[^0-9.\-]'), '')) ?? 0) >= 5) {
      return '涨幅已大，宜分批止盈，忌追高满仓。';
    }
    if (p.startsWith('-') && (double.tryParse(p.replaceAll(RegExp(r'[^0-9.\-]'), '')) ?? 0).abs() >= 5) {
      return '跌幅较深，勿恐慌割肉，等企稳信号再动。';
    }
    if (trend.contains('强') || trend.contains('阳')) {
      return '短线动能尚可，可轻仓跟随，设好止损。';
    }
    if (trend.contains('阴') || trend.contains('承压')) {
      return '弱势震荡，宜观望或做T降本，勿加仓摊平。';
    }
    if (k != null && k.close < k.prevClose) {
      return '低于昨收，耐心等待放量反转。';
    }
    return '横盘蓄势，结合大盘与板块再定进退。';
  }

  static const _titles = {
    '上上签': '金光乍现',
    '上签': '小富即安',
    '中上签': '渐入佳境',
    '中签': '静水流深',
    '中下签': '守株待兔',
    '下签': '韬光养晦',
    '下下签': '潜龙勿用',
  };

  static const _emoji = {
    '上上签': '🧧',
    '上签': '✨',
    '中上签': '🌤',
    '中签': '🍵',
    '中下签': '🪷',
    '下签': '🌙',
    '下下签': '⛈',
  };

  static const _poems = {
    '上上签': [
      '金价扶摇九万里，满仓踏云上天梯。',
      '财神今日敲你窗，自选红肥绿也奇。',
      '克价上扬如破竹，宜买金条忌卖飞。',
    ],
    '上签': [
      '小涨怡情大涨伤身，三分贪七分稳。',
      '盘中波澜起，笑看账户绿转红。',
      '今日运势如温水，慢火熬粥最养人。',
    ],
    '中上签': [
      '云开见日一线天，轻仓试水也安然。',
      '春风得意马蹄疾，小步快跑胜狂奔。',
      '趋势初现莫心急，积少成多见真章。',
    ],
    '中签': [
      '横盘磨人心性，不如泡杯茶看K线。',
      '涨跌皆是客，本金才是主。',
      '市场不语，唯成交量知进退。',
    ],
    '中下签': [
      '绿水长流人未老，先把子弹攒一攒。',
      '莫在风雨夜加仓，天亮再说不迟。',
      '今日宜围观，不宜手痒。',
    ],
    '下签': [
      '财不入急门，先睡个好觉再说。',
      '跌停板里藏教训，钱包捂紧是正道。',
      '山重水复疑无路，关掉软件即转晴。',
    ],
    '下下签': [
      '乌云压顶宜蛰伏，留得青山不怕晚。',
      '深套之时最考验，止损纪律胜侥幸。',
      '今日不宜大动作，静观其变等转机。',
    ],
  };

  static const _actions = {
    '上上签': ['加仓黄金', '晒收益', '请同事喝奶茶', '把自选置顶'],
    '上签': ['定投一笔', '复盘昨日操作', '看看品牌金价', '收藏一句金句'],
    '中上签': ['小仓试探', '设置止盈位', '看看分时图', '记录操作心得'],
    '中签': ['喝茶看盘', '整理自选列表', '设置价格提醒', '啥也别动'],
    '中下签': ['删自选冷静', '只看黄金', '关掉分时图', '去摸鱼五分钟'],
    '下签': ['抱紧黄金', '早睡保平安', '写下今日教训', '减少盯盘'],
    '下下签': ['空仓休息', '复盘止损线', '远离短线冲动', '读一篇投资文'],
  };

  static String _advice(
    String level,
    double pct,
    String session,
    int up,
    int down,
    int flat,
    bool hasStocks,
    String wish,
  ) {
    final goldBit = pct >= 0
        ? '金价今日+${pct.toStringAsFixed(2)}%，财气${pct > 1 ? '偏旺' : '尚可'}。'
        : '金价今日${pct.toStringAsFixed(2)}%，宜守不宜攻。';
    final stockBit = !hasStocks ? '' : '自选气象：$up涨 $down跌${flat > 0 ? ' $flat平' : ''}。';
    final wishBit = wish.isNotEmpty ? '心念所至：$wish。' : '';
    final sessionBit = session == '交易中'
        ? '盘中天机易变，见好就收也是福。'
        : session == '休市'
            ? '休市宜养神，别跟K线较劲。'
            : '非交易时段，适合做梦不适合下单。';
    final levelBit = switch (level) {
      '上上签' || '上签' => '运势偏吉，但仍需风控。',
      '中上签' || '中签' => '平稳为上，勿因一时冲动改策略。',
      _ => '运势偏弱，守本金第一。',
    };
    return '$wishBit$goldBit$stockBit$sessionBit$levelBit';
  }
}
