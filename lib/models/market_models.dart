class MarketSnapshot {
  const MarketSnapshot({
    this.usdPrice = 0,
    this.cnyPrice = 0,
    this.exchangeRate = 0,
    this.timeText = '--:--:--',
    this.dayChange = 0,
    this.dayChangePct = 0,
    this.error = '',
    this.loading = true,
  });

  final double usdPrice;
  final double cnyPrice;
  final double exchangeRate;
  final String timeText;
  final double dayChange;
  final double dayChangePct;
  final String error;
  final bool loading;

  MarketSnapshot copyWith({
    double? usdPrice,
    double? cnyPrice,
    double? exchangeRate,
    String? timeText,
    double? dayChange,
    double? dayChangePct,
    String? error,
    bool? loading,
  }) {
    return MarketSnapshot(
      usdPrice: usdPrice ?? this.usdPrice,
      cnyPrice: cnyPrice ?? this.cnyPrice,
      exchangeRate: exchangeRate ?? this.exchangeRate,
      timeText: timeText ?? this.timeText,
      dayChange: dayChange ?? this.dayChange,
      dayChangePct: dayChangePct ?? this.dayChangePct,
      error: error ?? this.error,
      loading: loading ?? this.loading,
    );
  }
}

class ShopGoldItem {
  const ShopGoldItem({required this.name, required this.price});
  final String name;
  final String price;
}

class PricePoint {
  const PricePoint({required this.timestamp, required this.cny, this.usd = 0});
  final double timestamp;
  final double cny;
  final double usd;

  Map<String, dynamic> toJson() => {'t': timestamp, 'cny': cny, 'usd': usd};

  factory PricePoint.fromJson(Map<String, dynamic> j) => PricePoint(
        timestamp: (j['t'] as num).toDouble(),
        cny: (j['cny'] as num).toDouble(),
        usd: (j['usd'] as num?)?.toDouble() ?? 0,
      );
}

class StockRowMeta {
  const StockRowMeta({
    this.code = '',
    this.delta = 0,
    this.commi = 0,
    this.avg = 0,
    this.b1 = 0,
    this.s1 = 0,
  });

  final String code;
  final int delta;
  final int commi;
  final int avg;
  final int b1;
  final int s1;
}

class StockKlineData {
  const StockKlineData({
    required this.open,
    required this.close,
    required this.high,
    required this.low,
    required this.prevClose,
  });

  final double open;
  final double close;
  final double high;
  final double low;
  final double prevClose;
}

class StockRow {
  const StockRow({
    required this.cells,
    required this.meta,
    this.kline,
  });

  final List<String> cells;
  final StockRowMeta meta;
  final StockKlineData? kline;
}

class StockBoard {
  const StockBoard({
    this.rows = const [],
    this.headers = const [],
    this.error = '',
    this.codesCount = 0,
  });

  final List<StockRow> rows;
  final List<String> headers;
  final String error;
  final int codesCount;
}

class StockDetail {
  const StockDetail({
    required this.code,
    required this.name,
    required this.price,
    required this.change,
    required this.changePct,
    required this.open,
    required this.high,
    required this.low,
    required this.prevClose,
  });

  final String code;
  final String name;
  final double price;
  final double change;
  final double changePct;
  final double open;
  final double high;
  final double low;
  final double prevClose;
}

class StockChartPoint {
  const StockChartPoint({required this.timestamp, required this.price});
  final double timestamp;
  final double price;
}

enum MainTab { gold, stock, fortune }

enum ViewMode { normal, mini, hidden }

class MarketState {
  const MarketState({
    this.snapshot = const MarketSnapshot(),
    this.brands = const [],
    this.banks = const [],
    this.sentence = '',
    this.stocks = const StockBoard(),
    this.activeTab = MainTab.gold,
    this.selectedStock = '',
    this.chartRange = '24H',
    this.stockChartPoints = const [],
    this.stockChartCode = '',
    this.refreshHint = '',
  });

  final MarketSnapshot snapshot;
  final List<ShopGoldItem> brands;
  final List<ShopGoldItem> banks;
  final String sentence;
  final StockBoard stocks;
  final MainTab activeTab;
  final String selectedStock;
  final String chartRange;
  final List<StockChartPoint> stockChartPoints;
  final String stockChartCode;
  final String refreshHint;

  MarketState copyWith({
    MarketSnapshot? snapshot,
    List<ShopGoldItem>? brands,
    List<ShopGoldItem>? banks,
    String? sentence,
    StockBoard? stocks,
    MainTab? activeTab,
    String? selectedStock,
    String? chartRange,
    List<StockChartPoint>? stockChartPoints,
    String? stockChartCode,
    String? refreshHint,
  }) {
    return MarketState(
      snapshot: snapshot ?? this.snapshot,
      brands: brands ?? this.brands,
      banks: banks ?? this.banks,
      sentence: sentence ?? this.sentence,
      stocks: stocks ?? this.stocks,
      activeTab: activeTab ?? this.activeTab,
      selectedStock: selectedStock ?? this.selectedStock,
      chartRange: chartRange ?? this.chartRange,
      stockChartPoints: stockChartPoints ?? this.stockChartPoints,
      stockChartCode: stockChartCode ?? this.stockChartCode,
      refreshHint: refreshHint ?? this.refreshHint,
    );
  }
}
