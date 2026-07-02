import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/market_models.dart';
import '../services/millionaire_service.dart';
import 'app_providers.dart';

typedef MillionaireBoard = Map<MillionaireHorizon, List<MillionaireEntry>>;

class MillionaireNotifier extends StateNotifier<AsyncValue<MillionaireBoard>> {
  MillionaireNotifier(this.ref) : super(const AsyncValue.data({}));

  final Ref ref;
  bool _sessionLoaded = false;

  /// 进入自选页时调用；同一次停留内不重复请求。
  Future<void> ensureLoaded({bool force = false}) async {
    if (_sessionLoaded && !force) return;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_fetch);
    _sessionLoaded = true;
  }

  /// 离开自选页后清除，下次再进会重新拉取。
  void resetSession() {
    _sessionLoaded = false;
  }

  Future<MillionaireBoard> _fetch() async {
    final cfg = ref.read(configProvider);
    final board = ref.read(marketProvider).stocks;
    final repo = ref.read(marketRepositoryProvider);
    final codes = cfg.stockCodes;
    if (codes.isEmpty) return {};

    final nameByCode = <String, String>{
      for (final row in board.rows)
        row.meta.code: row.cells.length > 1 ? row.cells[1] : row.meta.code,
    };

    final results = await Future.wait(codes.map((code) async {
      try {
        final daily = await repo.fetchStockDailyHistory(code);
        return (code, daily);
      } catch (_) {
        return (code, <StockChartPoint>[]);
      }
    }));

    final out = <MillionaireHorizon, List<MillionaireEntry>>{
      for (final h in MillionaireHorizon.values) h: <MillionaireEntry>[],
    };

    for (final (code, daily) in results) {
      if (daily.isEmpty) continue;
      final name = nameByCode[code] ?? code;
      for (final h in MillionaireHorizon.values) {
        final entry = MillionaireService.buildEntry(
          code: code,
          name: name,
          daily: daily,
          horizon: h,
        );
        if (entry != null) out[h]!.add(entry);
      }
    }

    for (final h in MillionaireHorizon.values) {
      out[h]!.sort((a, b) {
        if (a.isProfitable && !b.isProfitable) return -1;
        if (!a.isProfitable && b.isProfitable) return 1;
        if (!a.isProfitable && !b.isProfitable) return b.returnPct.compareTo(a.returnPct);
        return a.principalNeeded.compareTo(b.principalNeeded);
      });
    }

    return out;
  }
}

final millionaireProvider =
    StateNotifierProvider<MillionaireNotifier, AsyncValue<MillionaireBoard>>((ref) {
  return MillionaireNotifier(ref);
});
