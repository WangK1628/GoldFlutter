import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/api/api_client.dart';
import '../data/api/market_repository.dart';
import '../data/local/local_store.dart';
import '../models/app_config.dart';
import '../models/market_models.dart';
import '../services/alert_service.dart';
import '../ui/widgets/toast.dart';
import '../utils/stock_code.dart';

final configStoreProvider = Provider<ConfigStore>((ref) => ConfigStore());
final historyStoreProvider = Provider<HistoryStore>((ref) => HistoryStore());
final alertServiceProvider = Provider<AlertService>((ref) => AlertService());

final marketRepositoryProvider = Provider<MarketRepository>((ref) {
  final config = ref.watch(configProvider);
  return MarketRepository(ApiClient(timeout: config.networkTimeout));
});

class ConfigNotifier extends StateNotifier<AppConfig> {
  ConfigNotifier(this._store) : super(_store.config);

  final ConfigStore _store;

  Future<void> load() async {
    await _store.load();
    state = _store.config;
  }

  Future<void> save() async {
    _store.update((_) => state);
    await _store.save();
  }

  void update(AppConfig Function(AppConfig) fn) {
    state = fn(state);
  }
}

final configProvider = StateNotifierProvider<ConfigNotifier, AppConfig>((ref) {
  return ConfigNotifier(ref.watch(configStoreProvider));
});

class MarketNotifier extends StateNotifier<MarketState> {
  MarketNotifier(this.ref) : super(const MarketState());

  final Ref ref;
  Timer? _priceTimer;
  Timer? _exchangeTimer;
  Timer? _shopTimer;
  Timer? _sentenceTimer;
  Timer? _stockTimer;
  Timer? _historyTimer;
  String _lastStockChartKey = '';

  Future<void> init() async {
    final history = ref.read(historyStoreProvider);
    await history.load();
    final repo = ref.read(marketRepositoryProvider);
    final open = repo.dayOpenFromHistory(history.points);
    if (open > 0) repo.resetDayOpen(open);
    await _refreshPrice();
    await _refreshExchange();
    await _refreshShop();
    await _refreshSentence();
    await _refreshStocks();
    _startTimers();
  }

  void _startTimers() {
    final cfg = ref.read(configProvider);
    _priceTimer?.cancel();
    _exchangeTimer?.cancel();
    _shopTimer?.cancel();
    _sentenceTimer?.cancel();
    _stockTimer?.cancel();
    _historyTimer?.cancel();

    _priceTimer = Timer.periodic(Duration(seconds: cfg.priceRefreshSeconds), (_) => _refreshPrice());
    _exchangeTimer = Timer.periodic(Duration(seconds: cfg.exchangeRefreshSeconds), (_) => _refreshExchange());
    _shopTimer = Timer.periodic(Duration(seconds: cfg.shopRefreshSeconds), (_) => _refreshShop());
    _sentenceTimer = Timer.periodic(Duration(seconds: cfg.sentenceRefreshSeconds), (_) => _refreshSentence());
    _stockTimer = Timer.periodic(Duration(seconds: cfg.stockRefreshSeconds), (_) => _refreshStocks());
    _historyTimer = Timer.periodic(const Duration(seconds: 30), (_) => ref.read(historyStoreProvider).save());
  }

  void restartTimers() => _startTimers();

  Future<void> refreshAll() async {
    state = state.copyWith(refreshHint: '正在刷新…');
    showToast(ref, '正在刷新…');
    await Future.wait([
      _refreshPrice(),
      _refreshExchange(),
      _refreshShop(),
      _refreshSentence(),
      _refreshStocks(),
    ]);
    state = state.copyWith(refreshHint: '');
  }

  Future<void> _refreshPrice() async {
    final snap = await ref.read(marketRepositoryProvider).fetchSnapshot();
    if (snap.cnyPrice > 0) {
      ref.read(historyStoreProvider).addPoint(snap.cnyPrice, snap.usdPrice);
      ref.read(alertServiceProvider).check(
            snap.cnyPrice,
            ref.read(configProvider),
            onSave: (cfg) {
              ref.read(configProvider.notifier).update((_) => cfg);
              ref.read(configProvider.notifier).save();
            },
            onPopup: (title, msg) => showToast(ref, '$title: $msg'),
            onNotify: (msg) => showToast(ref, msg),
          );
    }
    state = state.copyWith(snapshot: snap);
  }

  Future<void> _refreshExchange() async {
    await ref.read(marketRepositoryProvider).refreshExchange();
    await _refreshPrice();
  }

  Future<void> _refreshShop() async {
    try {
      final repo = ref.read(marketRepositoryProvider);
      final brands = await repo.fetchBrands();
      final banks = await repo.fetchBanks();
      state = state.copyWith(brands: brands, banks: banks);
    } catch (_) {}
  }

  Future<void> _refreshSentence() async {
    try {
      final text = await ref.read(marketRepositoryProvider).fetchSentence();
      state = state.copyWith(sentence: text);
    } catch (_) {}
  }

  Future<void> _refreshStocks() async {
    final cfg = ref.read(configProvider);
    if (!cfg.stockBoard) return;
    final board = await ref.read(marketRepositoryProvider).fetchStocks(
          codes: cfg.stockCodes,
          headers: cfg.visibleStockHeaders(),
          shortCode: cfg.shortCode,
        );
    state = state.copyWith(stocks: board);
    if (state.selectedStock.isNotEmpty) {
      await _loadStockChart(state.selectedStock);
    }
  }

  void setTab(MainTab tab) {
    ref.read(configProvider.notifier).update((c) {
      c.lastTab = switch (tab) {
        MainTab.gold => 'gold',
        MainTab.stock => 'stock',
        MainTab.fortune => 'fortune',
      };
      return c;
    });
    ref.read(configProvider.notifier).save();
    state = state.copyWith(activeTab: tab);
  }

  Future<void> selectStock(String code) async {
    ref.read(configProvider.notifier).update((c) {
      c.selectedCode = code;
      return c;
    });
    await ref.read(configProvider.notifier).save();
    state = state.copyWith(selectedStock: code);
    if (code.isEmpty) {
      state = state.copyWith(stockChartPoints: [], stockChartCode: '');
      _lastStockChartKey = '';
    } else {
      await _loadStockChart(code);
    }
  }

  Future<void> _loadStockChart(String code) async {
    if (code == _lastStockChartKey && state.stockChartPoints.isNotEmpty) return;
    final points = await ref.read(marketRepositoryProvider).fetchStockChart(code);
    _lastStockChartKey = code;
    state = state.copyWith(stockChartPoints: points, stockChartCode: code);
  }

  void setChartRange(String range) {
    ref.read(configProvider.notifier).update((c) {
      c.chartRange = range;
      return c;
    });
    ref.read(configProvider.notifier).save();
    state = state.copyWith(chartRange: range);
  }

  String? addStock(String raw) {
    final code = normalizeStockCode(raw);
    if (code == null) return '代码格式无效，示例：600519';
    final cfg = ref.read(configProvider);
    if (!cfg.stockCodes.contains(code)) {
      ref.read(configProvider.notifier).update((c) {
        c.stockCodes = [...c.stockCodes, code];
        return c;
      });
      ref.read(configProvider.notifier).save();
      _refreshStocks();
      showToast(ref, '已添加 $code');
    }
    return null;
  }

  void removeStock(String code) {
    ref.read(configProvider.notifier).update((c) {
      c.stockCodes = c.stockCodes.where((x) => x != code).toList();
      if (c.stockCodes.isEmpty) c.stockCodes = ['sh000001'];
      if (c.selectedCode == code) c.selectedCode = '';
      return c;
    });
    ref.read(configProvider.notifier).save();
    if (state.selectedStock == code) {
      state = state.copyWith(selectedStock: '', stockChartPoints: [], stockChartCode: '');
    }
    _refreshStocks();
  }

  @override
  void dispose() {
    _priceTimer?.cancel();
    _exchangeTimer?.cancel();
    _shopTimer?.cancel();
    _sentenceTimer?.cancel();
    _stockTimer?.cancel();
    _historyTimer?.cancel();
    super.dispose();
  }
}

final marketProvider = StateNotifierProvider<MarketNotifier, MarketState>((ref) {
  return MarketNotifier(ref);
});
