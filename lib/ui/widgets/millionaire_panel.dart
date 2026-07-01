import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_design.dart';
import '../../providers/millionaire_provider.dart';
import '../../services/millionaire_service.dart';
import 'gm_card.dart';

class MillionairePanel extends ConsumerStatefulWidget {
  const MillionairePanel({super.key});

  @override
  ConsumerState<MillionairePanel> createState() => _MillionairePanelState();
}

class _MillionairePanelState extends ConsumerState<MillionairePanel> {
  MillionaireHorizon _horizon = MillionaireHorizon.month;

  @override
  Widget build(BuildContext context) {
    final d = context.design;
    final boardAsync = ref.watch(millionaireProvider);

    return GmCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(d: d),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 6),
            child: _HorizonPicker(
              selected: _horizon,
              onChanged: (h) => setState(() => _horizon = h),
            ),
          ),
          Expanded(
            child: boardAsync.when(
              loading: () => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2, color: d.gold),
                    ),
                    const SizedBox(height: 8),
                    Text('测算财富路径…', style: TextStyle(fontSize: 11, color: d.textMuted)),
                  ],
                ),
              ),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    '数据加载失败\n$e',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: d.fall, height: 1.4),
                  ),
                ),
              ),
              data: (entries) {
                final list = entries[_horizon] ?? [];
                if (list.isEmpty) {
                  return Center(
                    child: Text(
                      '暂无自选\n或阶段无上涨',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: d.textMuted, height: 1.5),
                    ),
                  );
                }
                final best = list.first.principalNeeded;
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (_, i) => _EntryCard(
                    entry: list[i],
                    rank: i + 1,
                    bestPrincipal: best,
                    horizon: _horizon,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.d});
  final AppDesign d;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [d.gold.withValues(alpha: 0.22), d.goldLight.withValues(alpha: 0.08)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(d.radius)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('💰', style: TextStyle(fontSize: 16, shadows: [Shadow(color: d.gold.withValues(alpha: 0.5), blurRadius: 6)])),
              const SizedBox(width: 6),
              Text(
                '百万富翁',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: d.textPrimary,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '赚 100 万，各需多少本金？',
            style: TextStyle(fontSize: 10, color: d.textMuted, height: 1.3),
          ),
        ],
      ),
    );
  }
}

class _HorizonPicker extends StatelessWidget {
  const _HorizonPicker({required this.selected, required this.onChanged});

  final MillionaireHorizon selected;
  final ValueChanged<MillionaireHorizon> onChanged;

  @override
  Widget build(BuildContext context) {
    final d = context.design;
    return Row(
      children: MillionaireHorizon.values.map((h) {
        final on = h == selected;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Material(
              color: on ? d.gold.withValues(alpha: 0.18) : d.chipBg,
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                onTap: () => onChanged(h),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Text(
                    h.label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: on ? FontWeight.w700 : FontWeight.w500,
                      color: on ? d.gold : d.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _EntryCard extends StatelessWidget {
  const _EntryCard({
    required this.entry,
    required this.rank,
    required this.bestPrincipal,
    required this.horizon,
  });

  final MillionaireEntry entry;
  final int rank;
  final double bestPrincipal;
  final MillionaireHorizon horizon;

  static const _medals = ['🥇', '🥈', '🥉'];

  @override
  Widget build(BuildContext context) {
    final d = context.design;
    final profitable = entry.isProfitable;
    final progress = profitable && bestPrincipal > 0
        ? (bestPrincipal / entry.principalNeeded).clamp(0.05, 1.0)
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: rank == 1 && profitable
            ? d.gold.withValues(alpha: 0.1)
            : d.chipBg.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: rank == 1 && profitable ? d.gold.withValues(alpha: 0.45) : d.cardBorder.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                rank <= 3 ? _medals[rank - 1] : '#$rank',
                style: TextStyle(fontSize: rank <= 3 ? 14 : 11, color: d.textMuted),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  entry.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: d.textPrimary),
                ),
              ),
              Text(
                MillionaireService.formatReturn(entry.returnPct),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: profitable ? d.rise : d.fall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (!profitable)
            Text(
              '阶段下跌，难以「赚」到 100 万',
              style: TextStyle(fontSize: 10, color: d.textMuted),
            )
          else ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text('本金 ', style: TextStyle(fontSize: 10, color: d.textMuted)),
                Text(
                  MillionaireService.formatPrincipal(entry.principalNeeded),
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: d.gold),
                ),
              ],
            ),
            const SizedBox(height: 5),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 4,
                backgroundColor: d.cardBorder.withValues(alpha: 0.35),
                color: d.gold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${horizon.label} ${entry.startPrice.toStringAsFixed(2)} → ${entry.endPrice.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 9, color: d.textMuted),
            ),
          ],
        ],
      ),
    );
  }
}
