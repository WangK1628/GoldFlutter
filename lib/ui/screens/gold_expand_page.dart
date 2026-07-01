import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_design.dart';
import '../../providers/app_providers.dart';
import '../widgets/auto_scroll_table.dart';
import '../widgets/chart_cards.dart';
import '../widgets/price_panels.dart';
import '../widgets/sentence_quote.dart';
import '../widgets/window_chrome.dart';

/// 黄金扩展视图 — 更多信息一览。
class GoldExpandPage extends ConsumerWidget {
  const GoldExpandPage({super.key});

  static Future<void> open(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (_) => const GoldExpandPage(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final d = context.design;
    final state = ref.watch(marketProvider);
    final cfg = ref.watch(configProvider);
    final screen = MediaQuery.sizeOf(context);

    return ContentDialog(
      constraints: BoxConstraints(
        maxWidth: (screen.width - 24).clamp(480.0, 720.0),
        maxHeight: (screen.height - 24).clamp(420.0, 680.0),
      ),
      content: SizedBox(
        width: (screen.width - 48).clamp(460.0, 700.0),
        height: (screen.height - 80).clamp(400.0, 640.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            WindowDragRegion(
              child: Row(
                children: [
                  Icon(FluentIcons.circle_dollar, color: d.gold, size: 18),
                  const SizedBox(width: 8),
                  Text('黄金详情', style: FluentTheme.of(context).typography.subtitle),
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (cfg.goldPrice) const GoldPricePanel(hideSentence: true),
                    if (cfg.sentence && cfg.showSentence && state.sentence.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      SentenceQuote(text: state.sentence, large: true),
                    ],
                    if (cfg.goldChart && cfg.showChart) ...[
                      const SizedBox(height: 10),
                      const GoldChartCard(),
                    ],
                    if (cfg.brandGold && cfg.showBrand && state.brands.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      AutoScrollPriceTable(title: '品牌金价', items: state.brands, maxVisible: 8),
                    ],
                    if (cfg.bankGold && cfg.showBank && state.banks.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      AutoScrollPriceTable(title: '银行金条', items: state.banks, maxVisible: 8),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
