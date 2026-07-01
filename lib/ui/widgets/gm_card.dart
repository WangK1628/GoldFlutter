import 'package:flutter/material.dart';

import '../../core/app_design.dart';

/// 统一卡片容器，跟随当前设计主题。
class GmCard extends StatelessWidget {
  const GmCard({
    super.key,
    required this.child,
    this.padding,
    this.tint,
    this.elevated = false,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? tint;
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    final d = context.design;
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: padding ?? const EdgeInsets.all(12),
        decoration: d.cardDecoration(tint: tint, shadow: elevated),
        child: child,
      ),
    );
  }
}
