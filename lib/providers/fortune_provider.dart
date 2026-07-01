import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local/fortune_store.dart';
import '../services/fortune_service.dart';
import 'app_providers.dart';

/// 财神签 UI 状态：每日一签 + 再求一签（仅当前浏览，不覆盖每日签）。
class FortuneUiState {
  const FortuneUiState({
    this.loaded = false,
    this.daily,
    this.preview,
    this.teaserLevel = '中签',
  });

  final bool loaded;
  final FortuneStick? daily;
  final FortuneStick? preview;
  final String teaserLevel;

  bool get hasDaily => daily != null;
  FortuneStick? get display => preview ?? daily;
}

class FortuneNotifier extends StateNotifier<FortuneUiState> {
  FortuneNotifier(this.ref) : super(const FortuneUiState());

  final Ref ref;

  Future<void> load() async {
    final store = ref.read(fortuneStoreProvider);
    await store.load();
    final market = ref.read(marketProvider);
    final teaser = FortuneService.draw(
      gold: market.snapshot,
      stocks: market.stocks,
      sentence: market.sentence,
      wish: '',
      salt: DateTime.now().day * 9973,
    );
    state = FortuneUiState(
      loaded: true,
      daily: store.today?.stick,
      teaserLevel: teaser.level,
    );
  }

  Future<void> submitWish(String wish) async {
    final text = wish.trim();
    if (text.isEmpty) return;
    final store = ref.read(fortuneStoreProvider);
    await store.load();
    if (store.today != null) return;
    final market = ref.read(marketProvider);
    final stick = FortuneService.draw(
      gold: market.snapshot,
      stocks: market.stocks,
      sentence: market.sentence,
      wish: text,
      salt: Object.hash(text, DateTime.now().microsecondsSinceEpoch),
    );
    final key = _todayKey();
    await store.save(FortuneDailyRecord(date: key, wish: text, stick: stick));
    state = FortuneUiState(loaded: true, daily: stick, preview: null);
  }

  void redrawPreview() {
    final daily = state.daily;
    if (daily == null) return;
    final market = ref.read(marketProvider);
    final stick = FortuneService.redrawContent(
      base: daily,
      gold: market.snapshot,
      stocks: market.stocks,
      sentence: market.sentence,
    );
    state = FortuneUiState(
      loaded: true,
      daily: daily,
      preview: stick,
      teaserLevel: state.teaserLevel,
    );
  }

  void clearPreview() {
    state = FortuneUiState(loaded: true, daily: state.daily, teaserLevel: state.teaserLevel);
  }

  String _todayKey() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }
}

final fortuneUiProvider = StateNotifierProvider<FortuneNotifier, FortuneUiState>((ref) {
  return FortuneNotifier(ref);
});

/// 迷你窗读取今日签文（仅正式签，不含试签预览）。
final miniFortuneProvider = Provider<FortuneStick?>((ref) {
  final ui = ref.watch(fortuneUiProvider);
  return ui.daily;
});
