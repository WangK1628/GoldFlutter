import 'package:flutter/material.dart';

import 'package:flutter/services.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';



import '../../core/app_design.dart';

import '../../models/market_models.dart';

import '../../providers/app_providers.dart';

import '../widgets/animated_price.dart';

import '../widgets/gm_card.dart';

import '../widgets/sentence_quote.dart';
import '../widgets/toast.dart';



class GoldPricePanel extends ConsumerWidget {

  const GoldPricePanel({super.key, this.compact = false, this.hideSentence = false});



  final bool compact;
  final bool hideSentence;



  @override

  Widget build(BuildContext context, WidgetRef ref) {

    final state = ref.watch(marketProvider);

    final cfg = ref.watch(configProvider);

    final snap = state.snapshot;

    final d = context.design;



    if (!cfg.goldPrice) return const SizedBox.shrink();



    final priceText = snap.cnyPrice > 0 ? snap.cnyPrice.toStringAsFixed(2) : '--';



    return GmCard(

      child: Column(

        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          if (cfg.showDomestic)

            GestureDetector(

              onTap: snap.cnyPrice > 0

                  ? () {

                      Clipboard.setData(ClipboardData(text: priceText));

                      showToast(ref, '已复制 $priceText');

                    }

                  : null,

              child: Tooltip(

                message: '点击复制金价',

                child: Row(

                  crossAxisAlignment: CrossAxisAlignment.end,

                  children: [

                    AnimatedPrice(

                      value: snap.cnyPrice,

                      enabled: cfg.animation,

                      text: priceText,

                      style: TextStyle(

                        fontSize: compact ? 26 : 32,

                        fontWeight: FontWeight.w700,

                        height: 1,

                        color: d.gold,

                      ),

                    ),

                    const SizedBox(width: 6),

                    Padding(

                      padding: const EdgeInsets.only(bottom: 4),

                      child: Text('元/克', style: TextStyle(color: d.textMuted, fontSize: 12)),

                    ),

                  ],

                ),

              ),

            ),

          if (cfg.showDomestic) ...[

            const SizedBox(height: 4),

            Container(

              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),

              decoration: BoxDecoration(

                color: d.delta(snap.dayChange).withValues(alpha: 0.12),

                borderRadius: BorderRadius.circular(6),

              ),

              child: Text(

                '今日 ${snap.dayChange >= 0 ? '+' : ''}${snap.dayChange.toStringAsFixed(2)}  (${snap.dayChangePct >= 0 ? '+' : ''}${snap.dayChangePct.toStringAsFixed(2)}%)',

                style: TextStyle(color: d.delta(snap.dayChange), fontSize: 12, fontWeight: FontWeight.w500),

              ),

            ),

          ],

          if (!compact && (cfg.showInternational || cfg.showExchange)) ...[

            const SizedBox(height: 10),

            Row(

              children: [

                if (cfg.showInternational)

                  Expanded(

                    child: _Metric(

                      label: '国际金价',

                      value: snap.usdPrice > 0 ? '${snap.usdPrice.toStringAsFixed(2)} USD' : '--',

                    ),

                  ),

                if (cfg.showExchange)

                  Expanded(

                    child: _Metric(

                      label: '美元汇率',

                      value: snap.exchangeRate > 0 ? snap.exchangeRate.toStringAsFixed(4) : '--',

                    ),

                  ),

              ],

            ),

          ],

          if (!compact && !hideSentence && cfg.sentence && cfg.showSentence && state.sentence.isNotEmpty) ...[
            const SizedBox(height: 10),
            SentenceQuote(text: state.sentence),
          ],

        ],

      ),

    );

  }

}



class _Metric extends StatelessWidget {

  const _Metric({required this.label, required this.value});

  final String label;

  final String value;



  @override

  Widget build(BuildContext context) {

    final d = context.design;

    return Column(

      crossAxisAlignment: CrossAxisAlignment.start,

      children: [

        Text(label, style: TextStyle(fontSize: 10, color: d.textMuted)),

        Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: d.textPrimary)),

      ],

    );

  }

}



class StockPricePanel extends StatelessWidget {

  const StockPricePanel({super.key, required this.detail, this.loading = false});



  final StockDetail? detail;

  final bool loading;



  @override

  Widget build(BuildContext context) {

    final d = context.design;

    return GmCard(

      child: loading || detail == null

          ? SizedBox(

              height: 72,

              child: Center(child: Text('加载中…', style: TextStyle(color: d.textMuted))),

            )

          : _Body(detail: detail!),

    );

  }

}



class _Body extends StatelessWidget {

  const _Body({required this.detail});

  final StockDetail detail;



  @override

  Widget build(BuildContext context) {

    final d = context.design;

    return Column(

      crossAxisAlignment: CrossAxisAlignment.start,

      children: [

        Text(detail.name, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: d.textPrimary)),

        Text(detail.code, style: TextStyle(fontSize: 10, color: d.textMuted)),

        const SizedBox(height: 6),

        Text(

          detail.price.toStringAsFixed(2),

          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: d.delta(detail.change)),

        ),

        Text(

          '${detail.change >= 0 ? '+' : ''}${detail.change.toStringAsFixed(2)} (${detail.changePct >= 0 ? '+' : ''}${detail.changePct.toStringAsFixed(2)}%)',

          style: TextStyle(color: d.delta(detail.change), fontSize: 12),

        ),

        const SizedBox(height: 4),

        Text(

          '开 ${detail.open.toStringAsFixed(2)}  高 ${detail.high.toStringAsFixed(2)}  低 ${detail.low.toStringAsFixed(2)}',

          style: TextStyle(fontSize: 10, color: d.textSecondary),

        ),

      ],

    );

  }

}


