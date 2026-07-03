import 'dart:ui';

import '../models/app_config.dart';
import '../models/market_models.dart';

/// 窗口尺寸估算。
class WindowLayout {
  static const navHeight = 44.0;
  static const navMinWidth = 360.0;
  static const hPad = 16.0;
  static const wPad = 20.0;
  static const minWidth = 300.0;
  static const maxWidth = 900.0;
  static const settingsMinWidth = 560.0;
  static const settingsMinHeight = 540.0;
  static const settingsDialogWidth = 520.0;
  static const settingsDialogHeight = 460.0;
  static const detailPanelW = 252.0;
  static const millionairePanelW = 220.0;
  static const priceBlockH = 108.0;
  static const chartBlockH = 200.0;
  static const tableRowH = 32.0;
  static const stockToolbarH = 72.0;

  static const columnWidth = {
    '代码': 56.0,
    '名称': 88.0,
    '现价': 60.0,
    '涨跌值': 56.0,
    '涨跌幅': 56.0,
    '买一': 48.0,
    '卖一': 48.0,
    '委比': 50.0,
    '成交量': 64.0,
    '成交额': 64.0,
    '均价': 54.0,
    'K线': 44.0,
  };

  static double tableContentWidth(List<String> headers) {
    if (headers.isEmpty) return 220;
    return headers.fold<double>(0, (s, h) => s + (columnWidth[h] ?? 48));
  }

  static double estimateGoldWidth(AppConfig cfg) {
    var w = 320.0;
    if (cfg.goldPrice && cfg.showInternational && cfg.showDomestic) {
      w = 340.0;
    }
    return w.clamp(320.0, maxWidth);
  }

  static double estimateGoldHeight(AppConfig cfg, {int brandCount = 0, int bankCount = 0}) {
    var h = navHeight + hPad;
    if (cfg.goldPrice) h += priceBlockH + 12;
    if (cfg.goldChart && cfg.showChart) h += chartBlockH + 12;
    if (cfg.brandGold && cfg.showBrand && brandCount > 0) h += 80;
    if (cfg.bankGold && cfg.showBank && bankCount > 0) h += 72;
    return h.clamp(260, 580);
  }

  static double estimateStockWidth(AppConfig cfg, List<String> headers) {
    final tableW = tableContentWidth(headers);
    final contentW = detailPanelW + tableW + millionairePanelW + wPad + 24;
    return contentW.clamp(navMinWidth, maxWidth);
  }

  static double estimateStockHeight({
    required int rowCount,
    required bool selected,
  }) {
    final rows = rowCount.clamp(1, 12);
    final tableH = 36 + rows * tableRowH;
    final detailH = selected ? priceBlockH + chartBlockH + 28 : priceBlockH + 40;
    final listH = stockToolbarH + tableH;
    return (navHeight + hPad + (detailH > listH ? detailH : listH)).clamp(300, 600);
  }

  static double estimateFortuneWidth() => 320.0;

  static double estimateFortuneHeight() => navHeight + hPad + 500;

  static Size fitSize({
    required MainTab tab,
    required AppConfig cfg,
    required MarketState state,
  }) {
    if (tab == MainTab.fortune) {
      return Size(
        estimateFortuneWidth(),
        estimateFortuneHeight().clamp(460, 580),
      );
    }
    if (tab == MainTab.stock && cfg.stockBoard) {
      final headers = state.stocks.headers.isNotEmpty
          ? state.stocks.headers
          : cfg.visibleStockHeaders();
      return Size(
        estimateStockWidth(cfg, headers),
        estimateStockHeight(
          rowCount: state.stocks.rows.length,
          selected: state.selectedStock.isNotEmpty,
        ),
      );
    }
    return Size(
      estimateGoldWidth(cfg),
      estimateGoldHeight(
        cfg,
        brandCount: state.brands.length,
        bankCount: state.banks.length,
      ),
    );
  }
}
