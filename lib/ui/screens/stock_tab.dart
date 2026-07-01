import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';



import '../../core/app_design.dart';

import '../../data/api/stock_api.dart';

import '../../models/market_models.dart';

import '../../providers/app_providers.dart';
import '../../providers/millionaire_provider.dart';
import '../../services/window_layout.dart';

import '../../utils/stock_code.dart';

import '../widgets/chart_cards.dart';

import '../widgets/gm_card.dart';

import '../widgets/price_panels.dart';

import '../widgets/millionaire_panel.dart';
import '../widgets/stock_table.dart';
import '../widgets/toast.dart';



class StockTab extends ConsumerStatefulWidget {

  const StockTab({super.key});



  @override

  ConsumerState<StockTab> createState() => _StockTabState();

}



class _StockTabState extends ConsumerState<StockTab> {
  final _addController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(marketProvider).activeTab == MainTab.stock) {
        ref.read(millionaireProvider.notifier).ensureLoaded();
      }
    });
  }

  @override
  void dispose() {

    _addController.dispose();

    super.dispose();

  }



  @override

  Widget build(BuildContext context) {

    final state = ref.watch(marketProvider);

    final cfg = ref.watch(configProvider);

    final d = context.design;

    final selected = state.selectedStock;

    final detail = selected.isNotEmpty ? findStockDetail(state.stocks, selected) : null;

    final headers = state.stocks.headers.isNotEmpty

        ? state.stocks.headers

        : cfg.visibleStockHeaders();



    return Padding(

      padding: const EdgeInsets.fromLTRB(6, 4, 6, 6),

      child: Column(

        crossAxisAlignment: CrossAxisAlignment.stretch,

        children: [

          _StockToolbar(controller: _addController),

          const SizedBox(height: 6),

          Expanded(

            child: Row(

              crossAxisAlignment: CrossAxisAlignment.stretch,

              children: [

                SizedBox(

                  width: 252,

                  child: _DetailPanel(

                    selected: selected,

                    detail: detail,

                  ),

                ),

                VerticalDivider(width: 1, thickness: 1, color: d.cardBorder),

                const SizedBox(width: 6),

                Expanded(

                  child: StockTable(

                    headers: headers,

                    selected: selected,

                    showHeader: cfg.headerVisible,

                    showGrid: cfg.gridVisible,

                  ),

                ),

                VerticalDivider(width: 1, thickness: 1, color: d.cardBorder),

                const SizedBox(width: 6),

                const SizedBox(

                  width: WindowLayout.millionairePanelW,

                  child: MillionairePanel(),

                ),

              ],

            ),

          ),

        ],

      ),

    );

  }

}



class _StockToolbar extends ConsumerWidget {

  const _StockToolbar({required this.controller});



  final TextEditingController controller;



  @override

  Widget build(BuildContext context, WidgetRef ref) {

    final state = ref.watch(marketProvider);

    final board = state.stocks;

    final d = context.design;



    return GmCard(

      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),

      child: Row(

        children: [

          Text(sessionHint(), style: TextStyle(fontSize: 11, color: d.textMuted)),

          const SizedBox(width: 8),

          Expanded(

            child: SingleChildScrollView(

              scrollDirection: Axis.horizontal,

              child: Row(

                children: [

                  for (final row in board.rows)

                    Padding(

                      padding: const EdgeInsets.only(right: 6),

                      child: _Chip(

                        label: row.cells.length > 1 ? row.cells[1] : row.meta.code,

                        selected: row.meta.code == state.selectedStock,

                        onTap: () {

                          final code = row.meta.code;

                          final next = code == state.selectedStock ? '' : code;

                          ref.read(marketProvider.notifier).selectStock(next);

                        },

                      ),

                    ),

                ],

              ),

            ),

          ),

          SizedBox(

            width: 110,

            height: 32,

            child: TextField(

              controller: controller,

              style: TextStyle(fontSize: 12, color: d.textPrimary),

              decoration: InputDecoration(

                hintText: '添加 600519',

                hintStyle: TextStyle(fontSize: 11, color: d.textMuted),

                isDense: true,

                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),

                border: OutlineInputBorder(

                  borderRadius: BorderRadius.circular(8),

                  borderSide: BorderSide(color: d.cardBorder),

                ),

                suffixIcon: IconButton(

                  icon: Icon(Icons.add, size: 18, color: d.gold),

                  onPressed: () => _submit(context, ref),

                ),

              ),

              onSubmitted: (_) => _submit(context, ref),

            ),

          ),

        ],

      ),

    );

  }



  void _submit(BuildContext context, WidgetRef ref) {

    final err = ref.read(marketProvider.notifier).addStock(controller.text);
    if (err != null && context.mounted) {
      showToast(ref, err);
    }

    controller.clear();

  }

}



class _Chip extends StatelessWidget {

  const _Chip({required this.label, required this.selected, required this.onTap});



  final String label;

  final bool selected;

  final VoidCallback onTap;



  @override

  Widget build(BuildContext context) {

    final d = context.design;

    return FilterChip(

      label: Text(label, style: TextStyle(fontSize: 11, color: selected ? d.gold : d.textSecondary)),

      selected: selected,

      onSelected: (_) => onTap(),

      visualDensity: VisualDensity.compact,

      padding: EdgeInsets.zero,

      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,

      backgroundColor: d.chipBg,

      selectedColor: d.chipSelected,

      checkmarkColor: d.gold,

    );

  }

}



class _DetailPanel extends StatelessWidget {

  const _DetailPanel({required this.selected, required this.detail});



  final String selected;

  final StockDetail? detail;



  @override

  Widget build(BuildContext context) {

    final d = context.design;

    if (selected.isEmpty) {

      return Column(

        crossAxisAlignment: CrossAxisAlignment.stretch,

        children: [

          const GoldPricePanel(compact: true),

          const SizedBox(height: 8),

          Expanded(

            child: GmCard(

              child: Center(

                child: Text(

                  '点击右侧列表或上方芯片\n查看股票详情',

                  textAlign: TextAlign.center,

                  style: TextStyle(fontSize: 12, color: d.textMuted, height: 1.5),

                ),

              ),

            ),

          ),

        ],

      );

    }



    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StockPricePanel(detail: detail, loading: detail == null),
        const SizedBox(height: 8),
        const Expanded(
          child: SingleChildScrollView(
            child: StockChartCard(),
          ),
        ),
      ],
    );

  }

}


