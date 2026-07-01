import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';



import '../../core/app_design.dart';

import '../../providers/app_providers.dart';

import '../widgets/auto_scroll_table.dart';

import '../widgets/chart_cards.dart';
import '../widgets/price_panels.dart';



class GoldTab extends ConsumerWidget {

  const GoldTab({super.key});



  @override

  Widget build(BuildContext context, WidgetRef ref) {

    final cfg = ref.watch(configProvider);

    final state = ref.watch(marketProvider);

    final d = context.design;



    return SingleChildScrollView(

      padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),

      child: Column(

        crossAxisAlignment: CrossAxisAlignment.stretch,

        children: [

          if (cfg.goldPrice) const GoldPricePanel(),

          if (cfg.goldChart && cfg.showChart) ...[

            const SizedBox(height: 8),

            const GoldChartCard(),

          ],

          if (cfg.brandGold && cfg.showBrand && state.brands.isNotEmpty) ...[

            const SizedBox(height: 8),

            AutoScrollPriceTable(title: '品牌金价', items: state.brands),

          ],

          if (cfg.bankGold && cfg.showBank && state.banks.isNotEmpty) ...[

            const SizedBox(height: 8),

            AutoScrollPriceTable(title: '银行金条', items: state.banks),

          ],

          if (state.brands.isEmpty && state.banks.isEmpty && !cfg.goldPrice)

            Padding(

              padding: const EdgeInsets.all(24),

              child: Text(

                '请在设置中启用插件',

                textAlign: TextAlign.center,

                style: TextStyle(color: d.textMuted, fontSize: 12),

              ),

            ),

        ],

      ),

    );

  }

}


