import '../models/market_models.dart';

/// 阶段收益与「赚 100 万所需本金」计算。
class MillionaireEntry {
  const MillionaireEntry({
    required this.code,
    required this.name,
    required this.returnPct,
    required this.principalNeeded,
    required this.startPrice,
    required this.endPrice,
  });

  final String code;
  final String name;
  /// 阶段涨跌幅（百分比，如 15.2 表示 +15.2%）
  final double returnPct;
  /// 赚取 100 万利润所需本金；<=0 涨幅时无效
  final double principalNeeded;
  final double startPrice;
  final double endPrice;

  bool get isProfitable => returnPct > 0 && principalNeeded.isFinite;
}

enum MillionaireHorizon {
  month('近一月', 22),
  halfYear('半年', 120),
  year('一年', 250);

  const MillionaireHorizon(this.label, this.tradingDays);
  final String label;
  final int tradingDays;
}

class MillionaireService {
  static const targetProfit = 1000000.0;

  static double? periodReturnPct(List<StockChartPoint> daily, int tradingDays) {
    if (daily.length < 2) return null;
    final end = daily.last.price;
    final startIdx = daily.length - tradingDays - 1;
    final idx = startIdx < 0 ? 0 : startIdx;
    final start = daily[idx].price;
    if (start <= 0) return null;
    return (end - start) / start * 100;
  }

  static double principalForProfit(double returnPct) {
    if (returnPct <= 0) return double.infinity;
    return targetProfit / (returnPct / 100);
  }

  static MillionaireEntry? buildEntry({
    required String code,
    required String name,
    required List<StockChartPoint> daily,
    required MillionaireHorizon horizon,
  }) {
    final pct = periodReturnPct(daily, horizon.tradingDays);
    if (pct == null) return null;
    final end = daily.last.price;
    final startIdx = daily.length - horizon.tradingDays - 1;
    final idx = startIdx < 0 ? 0 : startIdx;
    final start = daily[idx].price;
    return MillionaireEntry(
      code: code,
      name: name,
      returnPct: pct,
      principalNeeded: principalForProfit(pct),
      startPrice: start,
      endPrice: end,
    );
  }

  static String formatPrincipal(double value) {
    if (!value.isFinite || value <= 0) return '—';
    if (value >= 100000000) return '${(value / 100000000).toStringAsFixed(2)} 亿';
    if (value >= 10000) return '${(value / 10000).toStringAsFixed(1)} 万';
    return '${value.toStringAsFixed(0)} 元';
  }

  static String formatReturn(double pct) {
    final sign = pct > 0 ? '+' : '';
    return '$sign${pct.toStringAsFixed(1)}%';
  }
}
