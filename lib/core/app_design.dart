import 'package:fluent_ui/fluent_ui.dart';

import '../models/app_config.dart';

/// 设计令牌 — 四套主题预设。
class AppDesign {
  const AppDesign({
    required this.name,
    required this.isDark,
    required this.scaffold,
    required this.card,
    required this.cardBorder,
    required this.navGradientStart,
    required this.navGradientEnd,
    required this.navAccent,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.rise,
    required this.fall,
    required this.gold,
    required this.goldLight,
    required this.chartLine,
    required this.chipBg,
    required this.chipSelected,
    required this.miniPill,
    required this.shadow,
    required this.radius,
  });

  final String name;
  final bool isDark;
  final Color scaffold;
  final Color card;
  final Color cardBorder;
  final Color navGradientStart;
  final Color navGradientEnd;
  final Color navAccent;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color rise;
  final Color fall;
  final Color gold;
  final Color goldLight;
  final Color chartLine;
  final Color chipBg;
  final Color chipSelected;
  final Color miniPill;
  final List<BoxShadow> shadow;
  final double radius;

  static const presets = {
    'gold_luxe': _goldLuxe,
    'midnight': _midnight,
    'aurora': _aurora,
    'classic': _classic,
  };

  static AppDesign resolve(AppConfig cfg) {
    if (cfg.theme == 'dark' && cfg.themePreset == 'classic') {
      return _midnight;
    }
    return presets[cfg.themePreset] ?? (cfg.theme == 'dark' ? _midnight : _goldLuxe);
  }

  BoxDecoration cardDecoration({Color? tint, bool shadow = true}) => BoxDecoration(
        color: tint ?? card,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: cardBorder.withValues(alpha: 0.55)),
        boxShadow: shadow ? this.shadow : null,
      );

  BoxDecoration navDecoration() => BoxDecoration(
        gradient: LinearGradient(
          colors: [navGradientStart, navGradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: navGradientStart.withValues(alpha: 0.35),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      );

  Color delta(num v) {
    if (v > 0) return rise;
    if (v < 0) return fall;
    return textMuted;
  }

  static const _goldLuxe = AppDesign(
    name: 'Gold Luxe',
    isDark: false,
    scaffold: Color(0xFFF4F1EA),
    card: Color(0xFFFFFBF5),
    cardBorder: Color(0xFFE8DFD0),
    navGradientStart: Color(0xFF1C1917),
    navGradientEnd: Color(0xFF292524),
    navAccent: Color(0xFFD4AF37),
    textPrimary: Color(0xFF1C1917),
    textSecondary: Color(0xFF57534E),
    textMuted: Color(0xFF78716C),
    rise: Color(0xFFDC2626),
    fall: Color(0xFF16A34A),
    gold: Color(0xFFB8860B),
    goldLight: Color(0xFFF4D03F),
    chartLine: Color(0xFFB8860B),
    chipBg: Color(0xFFF5F0E6),
    chipSelected: Color(0xFFFFF8E7),
    miniPill: Color(0xE6121010),
    shadow: [BoxShadow(color: Color(0x1A78350F), blurRadius: 16, offset: Offset(0, 4))],
    radius: 14,
  );

  static const _midnight = AppDesign(
    name: 'Midnight',
    isDark: true,
    scaffold: Color(0xFF0C0F14),
    card: Color(0xFF151B24),
    cardBorder: Color(0xFF243044),
    navGradientStart: Color(0xFF0A0E17),
    navGradientEnd: Color(0xFF141C2B),
    navAccent: Color(0xFF60A5FA),
    textPrimary: Color(0xFFF1F5F9),
    textSecondary: Color(0xFFCBD5E1),
    textMuted: Color(0xFF94A3B8),
    rise: Color(0xFFF87171),
    fall: Color(0xFF4ADE80),
    gold: Color(0xFFFBBF24),
    goldLight: Color(0xFFFDE68A),
    chartLine: Color(0xFF60A5FA),
    chipBg: Color(0xFF1E293B),
    chipSelected: Color(0xFF1E3A5F),
    miniPill: Color(0xE60C0F14),
    shadow: [BoxShadow(color: Color(0x40000000), blurRadius: 20, offset: Offset(0, 6))],
    radius: 14,
  );

  static const _aurora = AppDesign(
    name: 'Aurora',
    isDark: true,
    scaffold: Color(0xFF0F0A1A),
    card: Color(0xFF1A1228),
    cardBorder: Color(0xFF3B2D55),
    navGradientStart: Color(0xFF1A0B2E),
    navGradientEnd: Color(0xFF2D1B4E),
    navAccent: Color(0xFFA78BFA),
    textPrimary: Color(0xFFF5F3FF),
    textSecondary: Color(0xFFDDD6FE),
    textMuted: Color(0xFFA78BFA),
    rise: Color(0xFFFB7185),
    fall: Color(0xFF34D399),
    gold: Color(0xFFC4B5FD),
    goldLight: Color(0xFFEDE9FE),
    chartLine: Color(0xFF818CF8),
    chipBg: Color(0xFF2E1065),
    chipSelected: Color(0xFF4C1D95),
    miniPill: Color(0xE61A0B2E),
    shadow: [BoxShadow(color: Color(0x406366F1), blurRadius: 18, offset: Offset(0, 4))],
    radius: 16,
  );

  static const _classic = AppDesign(
    name: 'Classic Blue',
    isDark: false,
    scaffold: Color(0xFFF5F7FA),
    card: Color(0xFFFFFFFF),
    cardBorder: Color(0xFFE5E7EB),
    navGradientStart: Color(0xFF0078D4),
    navGradientEnd: Color(0xFF005A9E),
    navAccent: Color(0xFF90CDF4),
    textPrimary: Color(0xFF111827),
    textSecondary: Color(0xFF4B5563),
    textMuted: Color(0xFF9CA3AF),
    rise: Color(0xFFE53935),
    fall: Color(0xFF43A047),
    gold: Color(0xFF0078D4),
    goldLight: Color(0xFF429CE3),
    chartLine: Color(0xFF0078D4),
    chipBg: Color(0xFFEFF6FF),
    chipSelected: Color(0xFFDBEAFE),
    miniPill: Color(0xE6000000),
    shadow: [BoxShadow(color: Color(0x1A000000), blurRadius: 12, offset: Offset(0, 4))],
    radius: 12,
  );
}

FluentThemeData buildFluentTheme(AppConfig cfg) {
  final d = AppDesign.resolve(cfg);
  return FluentThemeData(
    brightness: d.isDark ? Brightness.dark : Brightness.light,
    accentColor: AccentColor.swatch({
      'darkest': d.navGradientEnd,
      'darker': d.navGradientStart,
      'dark': d.gold,
      'normal': d.gold,
      'light': d.goldLight,
      'lighter': d.goldLight.withValues(alpha: 0.6),
      'lightest': d.chipSelected,
    }),
    typography: Typography.raw(
      title: TextStyle(fontFamily: cfg.fontFamily, fontSize: cfg.fontSize + 2.0, fontWeight: FontWeight.w600, color: d.textPrimary),
      body: TextStyle(fontFamily: cfg.fontFamily, fontSize: cfg.fontSize.toDouble(), color: d.textPrimary),
      caption: TextStyle(fontFamily: cfg.fontFamily, fontSize: cfg.fontSize - 1.0, color: d.textMuted),
    ),
    visualDensity: VisualDensity.compact,
    micaBackgroundColor: d.scaffold,
  );
}

extension DesignContext on BuildContext {
  AppDesign get design {
    final el = dependOnInheritedWidgetOfExactType<DesignScope>();
    return el?.design ?? AppDesign._goldLuxe;
  }
}

class DesignScope extends InheritedWidget {
  const DesignScope({required this.design, required super.child, super.key});
  final AppDesign design;

  @override
  bool updateShouldNotify(DesignScope old) => design != old.design;
}
