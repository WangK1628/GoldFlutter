import 'package:flutter/material.dart';

import '../../core/app_design.dart';

/// 一句话展示 — 引语样式，非斜体，较大字号。
class SentenceQuote extends StatelessWidget {
  const SentenceQuote({
    super.key,
    required this.text,
    this.large = false,
  });

  final String text;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final d = context.design;
    final fontSize = large ? 15.0 : 13.5;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: large ? 14 : 10, vertical: large ? 12 : 8),
      decoration: BoxDecoration(
        color: d.chipBg.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: d.gold, width: 3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'KaiTi',
          fontFamilyFallback: const ['STKaiti', 'Microsoft YaHei UI Light', 'Microsoft YaHei', 'Segoe UI'],
          fontSize: fontSize,
          height: 1.55,
          letterSpacing: 0.4,
          color: d.textSecondary,
          fontWeight: FontWeight.w400,
        ),
        maxLines: large ? 4 : 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
