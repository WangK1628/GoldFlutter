import '../../core/constants.dart';
import '../../models/market_models.dart';
import 'api_client.dart';
import 'exchange_api.dart';
import 'gold_api.dart';
import 'sentence_api.dart';
import 'shop_api.dart';
import 'stock_api.dart';
import 'stock_chart_api.dart';

class MarketRepository {
  MarketRepository(this._client);

  final ApiClient _client;
  ApiClient get client => _client;
  double _exchangeRate = 0;
  double _dayOpenCny = 0;
  final _cache = <String, _CacheEntry>{};

  T? _cached<T>(String key, int seconds, T Function() fetch) {
    final hit = _cache[key];
    if (hit != null && DateTime.now().difference(hit.at).inSeconds < seconds) {
      return hit.data as T;
    }
    return null;
  }

  void _put(String key, Object data) => _cache[key] = _CacheEntry(data, DateTime.now());

  Future<MarketSnapshot> fetchSnapshot({int cacheSeconds = 0}) async {
    if (cacheSeconds > 0) {
      final hit = _cached<MarketSnapshot>('snap', cacheSeconds, () => throw StateError(''));
      if (hit != null) return hit;
    }
    try {
      final usd = await GoldApi(_client).fetchUsdPrice();
      if (_exchangeRate <= 0) {
        _exchangeRate = (await ExchangeApi(_client).fetchUsdCny()).rate;
      }
      final cny = usd * _exchangeRate / AppConstants.ozToGram;
      if (_dayOpenCny <= 0) _dayOpenCny = cny;
      final now = DateTime.now();
      final timeText =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
      final snap = MarketSnapshot(
        usdPrice: usd,
        cnyPrice: cny,
        exchangeRate: _exchangeRate,
        timeText: timeText,
        dayChange: cny - _dayOpenCny,
        dayChangePct: _dayOpenCny > 0 ? (cny - _dayOpenCny) / _dayOpenCny * 100 : 0,
        loading: false,
      );
      if (cacheSeconds > 0) _put('snap', snap);
      return snap;
    } catch (e) {
      return MarketSnapshot(error: e.toString(), loading: false);
    }
  }

  Future<double> refreshExchange() async {
    _exchangeRate = (await ExchangeApi(_client).fetchUsdCny()).rate;
    return _exchangeRate;
  }

  Future<List<ShopGoldItem>> fetchBrands() => ShopApi(_client).fetchBrands();
  Future<List<ShopGoldItem>> fetchBanks() => ShopApi(_client).fetchBanks();
  Future<String> fetchSentence() => SentenceApi(_client).fetch();

  Future<StockBoard> fetchStocks({
    required List<String> codes,
    required List<String> headers,
    bool shortCode = false,
    int cacheSeconds = 0,
  }) async {
    final key = 'stk:${codes.join(",")}:$shortCode';
    if (cacheSeconds > 0) {
      final hit = _cached<StockBoard>(key, cacheSeconds, () => throw StateError(''));
      if (hit != null) return hit;
    }
    final board = await StockApi(_client).fetchBoard(codes: codes, headers: headers, shortCode: shortCode);
    if (cacheSeconds > 0 && board.error.isEmpty) _put(key, board);
    return board;
  }

  Future<List<StockChartPoint>> fetchStockChart(String code) =>
      StockChartApi(_client).fetchIntraday(code);

  Future<List<StockChartPoint>> fetchStockDailyHistory(String code, {int datalen = 260}) =>
      StockChartApi(_client).fetchDailyHistory(code, datalen: datalen);

  void resetDayOpen(double cny) {
    _dayOpenCny = cny;
  }

  double dayOpenFromHistory(List<PricePoint> points) {
    if (points.isEmpty) return 0;
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day).millisecondsSinceEpoch / 1000;
    final todayPoints = points.where((p) => p.timestamp >= startOfDay).toList();
    if (todayPoints.isEmpty) return points.last.cny;
    return todayPoints.first.cny;
  }
}

class _CacheEntry {
  _CacheEntry(this.data, this.at);
  final Object data;
  final DateTime at;
}
