import 'dart:math' show pi, sin, cos;

import 'package:flutter/material.dart';

/// 七种签级对应装饰图 — 纯绘制，无需外部资源。
class FortuneLevelArt extends StatelessWidget {
  const FortuneLevelArt({super.key, required this.level, this.size = 72});

  final String level;
  final double size;

  static String normalize(String level) {
    if (level.contains('下下')) return '下下签';
    if (level.contains('中下')) return '中下签';
    if (level.contains('中上')) return '中上签';
    if (level.contains('上上')) return '上上签';
    if (level.contains('上签') || level == '上') return '上签';
    if (level.contains('下签') || level == '下') return '下签';
    return '中签';
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _FortuneLevelPainter(normalize(level))),
    );
  }
}

class _FortuneLevelPainter extends CustomPainter {
  _FortuneLevelPainter(this.level);

  final String level;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.shortestSide * 0.42;
    switch (level) {
      case '上上签':
        _drawSupreme(canvas, c, r);
      case '上签':
        _drawRisingSun(canvas, c, r, bright: true);
      case '中上签':
        _drawRisingSun(canvas, c, r, bright: false);
      case '中签':
        _drawBalance(canvas, c, r);
      case '中下签':
        _drawCloud(canvas, c, r, dim: true);
      case '下签':
        _drawMoon(canvas, c, r);
      case '下下签':
        _drawStorm(canvas, c, r);
      default:
        _drawBalance(canvas, c, r);
    }
  }

  void _drawSupreme(Canvas canvas, Offset c, double r) {
    final glow = Paint()
      ..shader = RadialGradient(colors: [const Color(0xFFFFD54F), const Color(0x00FFD54F)]).createShader(
        Rect.fromCircle(center: c, radius: r * 1.4),
      );
    canvas.drawCircle(c, r * 1.2, glow);
    for (var i = 0; i < 8; i++) {
      final a = i * pi / 4;
      canvas.drawLine(c, c + Offset(cos(a), sin(a)) * r * 1.1, Paint()..color = const Color(0xFFFFB300)..strokeWidth = 2.5);
    }
    canvas.drawCircle(c, r * 0.55, Paint()..color = const Color(0xFFFFD700));
    final text = TextPainter(
      text: const TextSpan(text: '财', style: TextStyle(color: Color(0xFFB71C1C), fontSize: 22, fontWeight: FontWeight.w900)),
      textDirection: TextDirection.ltr,
    )..layout();
    text.paint(canvas, c - Offset(text.width / 2, text.height / 2));
  }

  void _drawRisingSun(Canvas canvas, Offset c, double r, {required bool bright}) {
    final sunC = c + Offset(0, r * 0.15);
    final sunR = r * (bright ? 0.42 : 0.36);
    canvas.drawCircle(sunC, sunR, Paint()..color = bright ? const Color(0xFFFFB300) : const Color(0xFFFFCA28));
    for (var i = 0; i < 6; i++) {
      final a = -pi / 2 + (i - 2.5) * 0.35;
      canvas.drawLine(
        sunC + Offset(cos(a), sin(a)) * (sunR + 4),
        sunC + Offset(cos(a), sin(a)) * (sunR + 14),
        Paint()..color = const Color(0xFFFFA000)..strokeWidth = 2,
      );
    }
    final hill = Path()
      ..moveTo(c.dx - r * 1.1, c.dy + r * 0.55)
      ..quadraticBezierTo(c.dx - r * 0.2, c.dy - r * 0.1, c.dx + r * 1.1, c.dy + r * 0.55)
      ..close();
    canvas.drawPath(hill, Paint()..color = bright ? const Color(0xFF66BB6A) : const Color(0xFF81C784));
  }

  void _drawBalance(Canvas canvas, Offset c, double r) {
    canvas.drawCircle(c, r * 0.7, Paint()..color = const Color(0xFF8D6E63).withValues(alpha: 0.25));
    final yin = Paint()..color = const Color(0xFF424242);
    final yang = Paint()..color = const Color(0xFFF5F5F5);
    canvas.drawArc(Rect.fromCircle(center: c, radius: r * 0.55), -pi / 2, pi, true, yin);
    canvas.drawArc(Rect.fromCircle(center: c, radius: r * 0.55), pi / 2, pi, true, yang);
    canvas.drawCircle(c + Offset(0, -r * 0.275), r * 0.14, yang);
    canvas.drawCircle(c + Offset(0, r * 0.275), r * 0.14, yin);
  }

  void _drawCloud(Canvas canvas, Offset c, double r, {required bool dim}) {
    final color = dim ? const Color(0xFF90A4AE) : const Color(0xFFB0BEC5);
    void blob(Offset o, double s) => canvas.drawCircle(o, s, Paint()..color = color);
    blob(c + Offset(-r * 0.35, r * 0.05), r * 0.28);
    blob(c + Offset(r * 0.1, r * 0.0), r * 0.34);
    blob(c + Offset(r * 0.42, r * 0.08), r * 0.24);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(c.dx - r * 0.55, c.dy + r * 0.05, r * 1.1, r * 0.22), const Radius.circular(6)),
      Paint()..color = color,
    );
  }

  void _drawMoon(Canvas canvas, Offset c, double r) {
    canvas.drawCircle(c, r * 0.55, Paint()..color = const Color(0xFFCFD8DC));
    canvas.drawCircle(c + Offset(r * 0.22, -r * 0.12), r * 0.48, Paint()..color = const Color(0xFF37474F));
    for (var i = 0; i < 5; i++) {
      canvas.drawCircle(
        c + Offset(-r * 0.5 + i * r * 0.22, r * 0.55),
        1.2,
        Paint()..color = Colors.white.withValues(alpha: 0.7),
      );
    }
  }

  void _drawStorm(Canvas canvas, Offset c, double r) {
    _drawCloud(canvas, c + Offset(0, -r * 0.15), r * 0.85, dim: true);
    final bolt = Path()
      ..moveTo(c.dx + r * 0.05, c.dy + r * 0.05)
      ..lineTo(c.dx - r * 0.12, c.dy + r * 0.42)
      ..lineTo(c.dx + r * 0.02, c.dy + r * 0.28)
      ..lineTo(c.dx - r * 0.18, c.dy + r * 0.62);
    canvas.drawPath(bolt, Paint()..color = const Color(0xFFFFC107)..strokeWidth = 3..style = PaintingStyle.stroke);
  }

  @override
  bool shouldRepaint(covariant _FortuneLevelPainter old) => old.level != level;
}
