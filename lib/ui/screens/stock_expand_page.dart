import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_design.dart';
import '../../data/api/stock_api.dart';
import '../../data/api/stock_news_api.dart';
import '../../providers/app_providers.dart';
import '../widgets/chart_cards.dart';
import '../widgets/gm_card.dart';
import '../widgets/price_panels.dart';
import '../widgets/stock_table.dart';
import '../widgets/window_chrome.dart';

final stockNewsProvider = FutureProvider.family<List<StockNewsItem>, String>((ref, code) async {
  final board = ref.read(marketProvider).stocks;
  final detail = findStockDetail(board, code);
  final api = StockNewsApi(ref.read(marketRepositoryProvider).client);
  return api.fetchNews(code, name: detail?.name ?? '');
});

class StockExpandPage extends ConsumerStatefulWidget {
  const StockExpandPage({super.key});

  static Future<void> open(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (_) => const StockExpandPage(),
    );
  }

  @override
  ConsumerState<StockExpandPage> createState() => _StockExpandPageState();
}

class _StockExpandPageState extends ConsumerState<StockExpandPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(marketProvider);
      if (state.selectedStock.isEmpty && state.stocks.rows.isNotEmpty) {
        ref.read(marketProvider.notifier).selectStock(state.stocks.rows.first.meta.code);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final d = context.design;
    final state = ref.watch(marketProvider);
    final cfg = ref.watch(configProvider);
    final screen = MediaQuery.sizeOf(context);
    final selected = state.selectedStock.isNotEmpty
        ? state.selectedStock
        : (state.stocks.rows.isNotEmpty ? state.stocks.rows.first.meta.code : '');
    final detail = selected.isNotEmpty ? findStockDetail(state.stocks, selected) : null;
    final headers = state.stocks.headers.isNotEmpty ? state.stocks.headers : cfg.visibleStockHeaders();
    final newsAsync = selected.isNotEmpty ? ref.watch(stockNewsProvider(selected)) : null;

    return ContentDialog(
      constraints: BoxConstraints(
        maxWidth: (screen.width - 24).clamp(500.0, 760.0),
        maxHeight: (screen.height - 24).clamp(440.0, 720.0),
      ),
      content: SizedBox(
        width: (screen.width - 48).clamp(480.0, 740.0),
        height: (screen.height - 80).clamp(420.0, 680.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            WindowDragRegion(
              child: Row(
                children: [
                  Icon(FluentIcons.line_chart, color: d.gold, size: 18),
                  const SizedBox(width: 8),
                  Text('自选扩展', style: FluentTheme.of(context).typography.subtitle),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(FluentIcons.cancel, size: 14),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: 310,
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (selected.isNotEmpty)
                            StockPricePanel(detail: detail, loading: detail == null)
                          else
                            GmCard(
                              child: Text('请选择股票', style: TextStyle(color: d.textMuted, fontSize: 12)),
                            ),
                          const SizedBox(height: 8),
                          const StockChartCard(),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 120,
                            child: ClipRect(
                              child: StockTable(
                                headers: headers,
                                selected: selected,
                                showHeader: cfg.headerVisible,
                                showGrid: cfg.gridVisible,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GmCard(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            selected.isNotEmpty ? '${detail?.name ?? selected} · 资讯' : '股票资讯',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: d.textPrimary),
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: selected.isEmpty
                                ? Center(child: Text('暂无自选', style: TextStyle(color: d.textMuted)))
                                : newsAsync == null
                                    ? const SizedBox.shrink()
                                    : newsAsync.when(
                                        loading: () => const Center(child: ProgressRing()),
                                        error: (_, __) => Center(
                                          child: Text('资讯加载失败', style: TextStyle(color: d.textMuted, fontSize: 12)),
                                        ),
                                        data: (items) => items.isEmpty
                                            ? Center(child: Text('暂无相关资讯', style: TextStyle(color: d.textMuted, fontSize: 12)))
                                            : ListView.separated(
                                                itemCount: items.length,
                                                separatorBuilder: (_, __) => Padding(
                                                  padding: const EdgeInsets.symmetric(vertical: 6),
                                                  child: Container(height: 1, color: d.cardBorder),
                                                ),
                                                itemBuilder: (_, i) => _NewsTile(item: items[i]),
                                              ),
                                      ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NewsTile extends StatelessWidget {
  const _NewsTile({required this.item});
  final StockNewsItem item;

  @override
  Widget build(BuildContext context) {
    final d = context.design;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.title,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: d.textPrimary, height: 1.35),
        ),
        if (item.time.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(item.time, style: TextStyle(fontSize: 10, color: d.textMuted)),
        ],
        if (item.summary.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            item.summary,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11, color: d.textSecondary, height: 1.4),
          ),
        ],
      ],
    );
  }
}
