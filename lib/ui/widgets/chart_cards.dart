import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/app_design.dart';
import '../../core/constants.dart';
import '../../models/market_models.dart';
import '../../providers/app_providers.dart';
import 'gm_card.dart';

class GoldChartCard extends ConsumerWidget {
  const GoldChartCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cfg = ref.watch(configProvider);
    final state = ref.watch(marketProvider);
    final d = context.design;
    if (!cfg.goldChart || !cfg.showChart) return const SizedBox.shrink();

    final points = ref.watch(historyStoreProvider).range(state.chartRange);

    return GmCard(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('历史走势', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: d.textPrimary)),
              const Spacer(),
              Text('元/克', style: TextStyle(fontSize: 10, color: d.textMuted)),
            ],
          ),
          const SizedBox(height: 6),
          if (points.length < 2)
            SizedBox(
              height: 130,
              child: Center(child: Text('暂无走势数据', style: TextStyle(color: d.textMuted, fontSize: 12))),
            )
          else
            AxisLineChart(
              values: points.map((p) => p.cny).toList(),
              timestamps: points.map((p) => p.timestamp).toList(),
              yUnit: '元/克',
              height: 130,
              lineColor: d.chartLine,
            ),
          const SizedBox(height: 8),
          Row(
            children: AppConstants.chartRanges.map((r) {
              final selected = state.chartRange == r;
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: FilterChip(
                  label: Text(r, style: TextStyle(fontSize: 11, color: selected ? d.gold : d.textSecondary)),
                  selected: selected,
                  onSelected: (_) => ref.read(marketProvider.notifier).setChartRange(r),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  backgroundColor: d.chipBg,
                  selectedColor: d.chipSelected,
                  checkmarkColor: d.gold,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class StockChartCard extends ConsumerWidget {
  const StockChartCard({super.key});

  static const minChartHeight = 168.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final points = ref.watch(marketProvider).stockChartPoints;
    final d = context.design;

    return GmCard(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text('分时走势', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: d.textPrimary)),
              const Spacer(),
              Text('价格', style: TextStyle(fontSize: 10, color: d.textMuted)),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: minChartHeight,
            child: points.length < 2
                ? Center(child: Text('分时加载中…', style: TextStyle(color: d.textMuted, fontSize: 12)))
                : AxisLineChart(
                    values: points.map((p) => p.price).toList(),
                    timestamps: points.map((p) => p.timestamp).toList(),
                    height: minChartHeight,
                    lineColor: d.chartLine,
                    compactY: true,
                  ),
          ),
        ],
      ),
    );
  }
}

/// 带 X/Y 轴刻度的折线图。
class AxisLineChart extends StatelessWidget {
  const AxisLineChart({
    super.key,
    required this.values,
    required this.timestamps,
    this.yUnit = '',
    this.height = 120,
    this.lineColor,
    this.compactY = false,
  });

  final List<double> values;
  final List<double> timestamps;
  final String yUnit;
  final double height;
  final Color? lineColor;
  final bool compactY;

  static String _formatY(double value, double span, bool compact, String unit) {
    if (compact) {
      if (span < 0.05) return value.toStringAsFixed(3);
      if (span < 1) return value.toStringAsFixed(2);
      if (span < 20) return value.toStringAsFixed(2);
      return value.toStringAsFixed(1);
    }
    return value.toStringAsFixed(unit.isEmpty ? 2 : 1);
  }

  @override
  Widget build(BuildContext context) {
    final d = context.design;
    final color = lineColor ?? d.chartLine;
    if (values.length < 2) return SizedBox(height: height);

    final spots = List.generate(values.length, (i) => FlSpot(i.toDouble(), values[i]));
    final minY = values.reduce((a, b) => a < b ? a : b);
    final maxY = values.reduce((a, b) => a > b ? a : b);
    final rawSpan = (maxY - minY).abs();
    final yPad = rawSpan < 0.01 ? 1.0 : rawSpan * 0.12;
    final span = rawSpan < 0.01 ? 2.0 : rawSpan + yPad * 2;

    final timeFmt = DateFormat('HH:mm');
    final firstTs = DateTime.fromMillisecondsSinceEpoch((timestamps.first * 1000).round());
    final lastTs = DateTime.fromMillisecondsSinceEpoch((timestamps.last * 1000).round());
    final midIdx = values.length ~/ 2;
    final midTs = DateTime.fromMillisecondsSinceEpoch((timestamps[midIdx] * 1000).round());

    final yInterval = span / 2;
    final leftReserved = compactY ? 54.0 : 46.0;
    final bottomReserved = 28.0;

    return SizedBox(
      height: height,
      child: Padding(
        padding: const EdgeInsets.only(top: 4, right: 4),
        child: LineChart(
          LineChartData(
            minY: minY - yPad,
            maxY: maxY + yPad,
            minX: 0,
            maxX: (spots.length - 1).toDouble(),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: yInterval,
              getDrawingHorizontalLine: (_) => FlLine(color: d.cardBorder.withValues(alpha: 0.6), strokeWidth: 1),
            ),
            borderData: FlBorderData(
              show: true,
              border: Border(
                left: BorderSide(color: d.cardBorder),
                bottom: BorderSide(color: d.cardBorder),
              ),
            ),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: leftReserved,
                  interval: yInterval,
                  getTitlesWidget: (value, meta) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Text(
                        _formatY(value, span, compactY, yUnit),
                        style: TextStyle(fontSize: 9, color: d.textMuted, height: 1.1),
                        textAlign: TextAlign.right,
                      ),
                    );
                  },
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: bottomReserved,
                  interval: (spots.length - 1) / 2,
                  getTitlesWidget: (value, meta) {
                    final i = value.round();
                    Widget? label;
                    if (i == 0) {
                      label = Text(timeFmt.format(firstTs), style: TextStyle(fontSize: 9, color: d.textMuted));
                    } else if (i == spots.length - 1) {
                      label = Text(timeFmt.format(lastTs), style: TextStyle(fontSize: 9, color: d.textMuted));
                    } else if (i == spots.length ~/ 2) {
                      label = Text(timeFmt.format(midTs), style: TextStyle(fontSize: 9, color: d.textMuted));
                    }
                    if (label == null) return const SizedBox.shrink();
                    return Padding(padding: const EdgeInsets.only(top: 4), child: label);
                  },
                ),
              ),
            ),
            lineTouchData: const LineTouchData(enabled: false),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: color,
                barWidth: 2,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  color: color.withValues(alpha: 0.08),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MiniKlinePainter extends CustomPainter {
  MiniKlinePainter(this.data, this.color, {this.neutral = const Color(0xFF6B7280)});
  final StockKlineData data;
  final Color color;
  final Color neutral;

  @override
  void paint(Canvas canvas, Size size) {
    final o = data.open;
    final c = data.close;
    var h = data.high;
    var l = data.low;
    final p = data.prevClose;
    if (h < l) {
      final t = h;
      h = l;
      l = t;
    }

    final rect = Rect.fromLTWH(2, 2, size.width - 4, size.height - 4);
    final vpad = (rect.height * 0.14).clamp(2.0, 6.0);
    final krect = Rect.fromLTWH(rect.left, rect.top + vpad, rect.width, rect.height - vpad * 2);
    final ymin = [l, p].reduce((a, b) => a < b ? a : b);
    final ymax = [h, p].reduce((a, b) => a > b ? a : b);
    final span = (ymax - ymin).abs() < 0.001 ? 1.0 : ymax - ymin;

    double yFor(double v) => krect.top + (1 - (v - ymin) / span) * krect.height;

    final yO = yFor(o);
    final yC = yFor(c);
    final yH = yFor(h);
    final yL = yFor(l);
    final yP = yFor(p);
    final x = krect.center.dx;
    final bodyW = (krect.width * 0.42).clamp(5.0, 10.0);

    final dash = Paint()
      ..color = neutral.withValues(alpha: 0.75)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(x - bodyW, yP), Offset(x + bodyW, yP), dash);

    final kcolor = c > o ? color : (c < o ? color : neutral);
    final bodyTop = yO < yC ? yO : yC;
    final bodyBot = yO > yC ? yO : yC;
    final bodyH = (bodyBot - bodyTop).clamp(2.0, krect.height);

    final stroke = Paint()
      ..color = kcolor
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    final fill = Paint()
      ..color = kcolor
      ..style = PaintingStyle.fill;

    if (c != o) {
      final bodyRect = Rect.fromLTWH(x - bodyW / 2, bodyTop, bodyW, bodyH);
      if (c < o) {
        canvas.drawRect(bodyRect, fill);
      } else {
        canvas.drawRect(bodyRect, stroke);
      }
    } else {
      canvas.drawLine(Offset(x - bodyW / 2, yC), Offset(x + bodyW / 2, yC), stroke);
    }
    if (yH < bodyTop) {
      canvas.drawLine(Offset(x, yH), Offset(x, bodyTop), stroke);
    }
    if (yL > bodyBot) {
      canvas.drawLine(Offset(x, bodyBot), Offset(x, yL), stroke);
    }
  }

  @override
  bool shouldRepaint(covariant MiniKlinePainter old) =>
      old.data.close != data.close || old.data.high != data.high;
}
