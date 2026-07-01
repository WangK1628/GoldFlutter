import 'package:flutter/material.dart';

import '../../core/app_design.dart';

/// 价格变动时短暂高亮闪烁。
class AnimatedPrice extends StatefulWidget {
  const AnimatedPrice({
    super.key,
    required this.value,
    required this.text,
    this.style,
    this.enabled = true,
  });

  final double value;
  final String text;
  final TextStyle? style;
  final bool enabled;

  @override
  State<AnimatedPrice> createState() => _AnimatedPriceState();
}

class _AnimatedPriceState extends State<AnimatedPrice>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<Color?> _colorAnim;
  double? _prev;
  int _dir = 0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _colorAnim = ColorTween(begin: Colors.transparent, end: Colors.transparent)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _prev = widget.value;
  }

  @override
  void didUpdateWidget(AnimatedPrice old) {
    super.didUpdateWidget(old);
    if (!widget.enabled || widget.value == _prev) return;
    _dir = widget.value > (_prev ?? widget.value) ? 1 : -1;
    _prev = widget.value;
    final d = context.design;
    final flash = _dir > 0 ? d.rise : d.fall;
    _colorAnim = ColorTween(begin: flash.withValues(alpha: 0.35), end: Colors.transparent)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward(from: 0);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) {
        final bg = _colorAnim.value;
        return DecoratedBox(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(6),
          ),
          child: child,
        );
      },
      child: Text(widget.text, style: widget.style),
    );
  }
}
