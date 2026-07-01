import '../../core/constants.dart';
import '../../models/market_models.dart';
import 'api_client.dart';

class StockChartApi {
  StockChartApi(this._client);
  final ApiClient _client;

  Future<List<StockChartPoint>> fetchIntraday(String code) async {
    final url =
        'https://money.finance.sina.com.cn/quotes_service/api/json_v2.php/'
        'CN_MarketData.getKLineData?symbol=$code&scale=5&ma=no&datalen=48';
    return _parseKlineList(await _fetchKlineJson(url));
  }

  /// 日 K 线历史 — scale=240 日线，用于阶段涨跌幅计算。
  Future<List<StockChartPoint>> fetchDailyHistory(String code, {int datalen = 260}) async {
    final url =
        'https://money.finance.sina.com.cn/quotes_service/api/json_v2.php/'
        'CN_MarketData.getKLineData?symbol=$code&scale=240&ma=no&datalen=$datalen';
    return _parseKlineList(await _fetchKlineJson(url));
  }

  Future<List<dynamic>> _fetchKlineJson(String url) async {
    return _client.getJsonList(
      url,
      headers: {'Referer': AppConstants.sinaReferer},
    );
  }

  List<StockChartPoint> _parseKlineList(List<dynamic> list) {
    final points = <StockChartPoint>[];
    for (final item in list) {
      if (item is! Map<String, dynamic>) continue;
      final day = item['day']?.toString() ?? '';
      final close = double.tryParse(item['close']?.toString() ?? '') ?? 0;
      if (day.isEmpty || close <= 0) continue;
      try {
        final dt = DateTime.parse(day.replaceFirst(' ', 'T'));
        points.add(StockChartPoint(timestamp: dt.millisecondsSinceEpoch / 1000, price: close));
      } catch (_) {}
    }
    points.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return points;
  }
}
