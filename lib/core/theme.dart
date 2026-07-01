import 'package:fluent_ui/fluent_ui.dart';

import 'app_design.dart';

/// 兼容旧引用 — 转发到默认主题。
class AppTheme {
  static AppDesign get _d => AppDesign.presets['gold_luxe']!;

  static Color riseColor() => _d.rise;
  static Color fallColor() => _d.fall;
  static Color deltaColor(num delta) => _d.delta(delta);

  static Color get border => _d.cardBorder;
  static Color get panelBg => _d.scaffold;
  static Color get cardBg => _d.card;
  static Color get navBlue => _d.gold;

  static BoxDecoration panel({double radius = 14}) => _d.cardDecoration();
  static BoxDecoration card({double radius = 10}) => _d.cardDecoration();
}
