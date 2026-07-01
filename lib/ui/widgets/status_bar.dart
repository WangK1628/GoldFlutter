import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_design.dart';
import '../../utils/stock_code.dart';
import '../../providers/app_providers.dart';

/// 底部状态栏：交易时段 + 最近更新时间。
class StatusBar extends ConsumerWidget {
  const StatusBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final d = context.design;
    final state = ref.watch(marketProvider);
    final snap = state.snapshot;

    return Container(
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: d.chipBg,
        border: Border(top: BorderSide(color: d.cardBorder)),
      ),
      child: Row(
        children: [
          Icon(Icons.circle, size: 6, color: d.navAccent),
          const SizedBox(width: 6),
          Text(sessionHint(), style: TextStyle(fontSize: 10, color: d.textMuted)),
          const Spacer(),
          Text(
            '更新 ${snap.timeText}',
            style: TextStyle(fontSize: 10, color: d.textMuted),
          ),
        ],
      ),
    );
  }
}
