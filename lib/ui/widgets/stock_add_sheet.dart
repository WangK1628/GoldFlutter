import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_design.dart';
import '../../models/market_models.dart';
import '../../providers/app_providers.dart';
import '../../utils/stock_code.dart';

/// 添加自选：先查询确认，再点击加入。
class StockAddSheet extends ConsumerStatefulWidget {
  const StockAddSheet({super.key});

  static Future<void> open(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => const StockAddSheet(),
    );
  }

  @override
  ConsumerState<StockAddSheet> createState() => _StockAddSheetState();
}

class _StockAddSheetState extends ConsumerState<StockAddSheet> {
  final _ctrl = TextEditingController();
  String _category = stockPresetCategories().first;
  bool _searching = false;
  StockLookup? _result;
  String? _searchError;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final raw = _ctrl.text.trim();
    if (raw.isEmpty) return;
    final parsed = parseStockInput(raw);
    if (!parsed.ok) {
      setState(() {
        _result = null;
        _searchError = parsed.error;
      });
      return;
    }
    setState(() {
      _searching = true;
      _result = null;
      _searchError = null;
    });
    final hit = await ref.read(marketProvider.notifier).lookupStock(raw);
    if (!mounted) return;
    setState(() {
      _searching = false;
      _result = hit;
      _searchError = hit == null ? '未找到相关股票，请检查代码' : null;
    });
  }

  void _addSymbol(String symbol, {String label = ''}) {
    ref.read(marketProvider.notifier).addStockBySymbol(symbol, label: label);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final d = context.design;
    final categories = stockPresetCategories();
    final presets = stockPresets.where((p) => p.category == _category).toList();

    return ContentDialog(
      title: const Text('添加自选'),
      content: SizedBox(
        width: 440,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            InfoLabel(
              label: '输入代码后查询',
              child: Row(
                children: [
                  Expanded(
                    child: TextBox(
                      controller: _ctrl,
                      placeholder: '600519 / 00700 / AAPL',
                      onSubmitted: (_) => _search(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _searching ? null : _search,
                    child: _searching
                        ? const SizedBox(width: 16, height: 16, child: ProgressRing(strokeWidth: 2))
                        : const Text('查询'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _buildSearchResult(d),
            const SizedBox(height: 12),
            Text('热门推荐', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: d.textPrimary)),
            const SizedBox(height: 8),
            SizedBox(
              height: 30,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (_, i) {
                  final c = categories[i];
                  final sel = c == _category;
                  return Button(
                    onPressed: () => setState(() => _category = c),
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.all(
                        sel ? d.gold.withValues(alpha: 0.15) : Colors.transparent,
                      ),
                    ),
                    child: Text(c, style: TextStyle(fontSize: 11, color: sel ? d.gold : null)),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 180),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: presets.length,
                itemBuilder: (_, i) {
                  final p = presets[i];
                  final tag = marketTag(marketOfCode(p.symbol));
                  return ListTile(
                    title: Text(p.name, style: const TextStyle(fontSize: 12)),
                    subtitle: Text('$tag · ${p.symbol}', style: TextStyle(fontSize: 10, color: d.textMuted)),
                    trailing: IconButton(
                      icon: Icon(FluentIcons.add, size: 14, color: d.gold),
                      onPressed: () => _addSymbol(p.symbol, label: p.name),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        Button(child: const Text('关闭'), onPressed: () => Navigator.pop(context)),
      ],
    );
  }

  Widget _buildSearchResult(AppDesign d) {
    if (_searching) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Center(child: Text('正在查询…', style: TextStyle(fontSize: 12, color: d.textMuted))),
      );
    }
    if (_searchError != null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: d.chipBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: d.cardBorder),
        ),
        child: Row(
          children: [
            Icon(FluentIcons.info, size: 14, color: d.textMuted),
            const SizedBox(width: 8),
            Expanded(child: Text(_searchError!, style: TextStyle(fontSize: 12, color: d.textMuted))),
          ],
        ),
      );
    }
    final r = _result;
    if (r == null) return const SizedBox.shrink();

    final pctColor = r.changePct.startsWith('+')
        ? d.rise
        : (r.changePct.startsWith('-') ? d.fall : d.textSecondary);

    return Button(
      onPressed: () => _addSymbol(r.symbol, label: r.name),
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.all(d.chipBg),
        padding: WidgetStateProperty.all(const EdgeInsets.all(12)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: d.gold.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(r.marketLabel, style: TextStyle(fontSize: 10, color: d.gold, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: d.textPrimary)),
                Text(r.symbol, style: TextStyle(fontSize: 10, color: d.textMuted)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(r.price, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: d.textPrimary)),
              Text(r.changePct, style: TextStyle(fontSize: 11, color: pctColor)),
            ],
          ),
          const SizedBox(width: 8),
          Icon(FluentIcons.add, size: 16, color: d.gold),
        ],
      ),
    );
  }
}
