import 'dart:math' show pi, sin;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_design.dart';
import '../../providers/app_providers.dart';
import '../../providers/fortune_provider.dart';
import '../../services/fortune_service.dart';
import '../widgets/fortune_level_art.dart';
import '../widgets/gm_card.dart';

/// 财神签 — 每日一签，首次输入所求后生成。
class FortuneTab extends ConsumerStatefulWidget {
  const FortuneTab({super.key});

  @override
  ConsumerState<FortuneTab> createState() => _FortuneTabState();
}

class _FortuneTabState extends ConsumerState<FortuneTab> with SingleTickerProviderStateMixin {
  final _wishController = TextEditingController();
  late final AnimationController _shake;

  @override
  void initState() {
    super.initState();
    _shake = AnimationController(vsync: this, duration: const Duration(milliseconds: 520));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(fortuneUiProvider.notifier).load();
    });
  }

  @override
  void dispose() {
    _shake.dispose();
    _wishController.dispose();
    super.dispose();
  }

  void _redraw() {
    ref.read(fortuneUiProvider.notifier).redrawPreview();
    _shake.forward(from: 0);
  }

  Future<void> _submitWish() async {
    final text = _wishController.text.trim();
    if (text.isEmpty) return;
    await ref.read(fortuneUiProvider.notifier).submitWish(text);
    _shake.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final d = context.design;
    final snap = ref.watch(marketProvider).snapshot;
    final ui = ref.watch(fortuneUiProvider);
    final daily = ui.daily;
    final content = ui.preview ?? daily;

    if (!ui.loaded) {
      return Center(child: CircularProgressIndicator(strokeWidth: 2, color: d.gold));
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '今日金价 ${snap.cnyPrice.toStringAsFixed(2)} 元/克 · 一日一签',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: d.textMuted),
          ),
          const SizedBox(height: 8),
          if (!ui.hasDaily) ...[
            Expanded(child: _WishForm(controller: _wishController, teaserLevel: ui.teaserLevel)),
            const SizedBox(height: 10),
            Material(
              color: d.gold,
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                onTap: _submitWish,
                borderRadius: BorderRadius.circular(10),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 11),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('🎋', style: TextStyle(fontSize: 16)),
                      SizedBox(width: 8),
                      Text(
                        '诚心求签',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1a1a1a)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ] else ...[
            Expanded(
              child: daily == null || content == null
                  ? const SizedBox.shrink()
                  : _FortuneCard(
                      header: daily,
                      content: content,
                      shake: _shake,
                      design: d,
                      contentOnlyShake: ui.preview != null,
                    ),
            ),
            if (ui.preview != null) ...[
              const SizedBox(height: 6),
              Text(
                '（再求一签仅换下方文案，今日签级不变）',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 10, color: d.textMuted),
              ),
            ],
            const SizedBox(height: 8),
            Material(
              color: d.gold,
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                onTap: _redraw,
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('🎋', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 8),
                      Text(
                        '再求一签',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: d.isDark ? Colors.white : const Color(0xFF1a1a1a),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _WishForm extends StatelessWidget {
  const _WishForm({required this.controller, required this.teaserLevel});

  final TextEditingController controller;
  final String teaserLevel;

  @override
  Widget build(BuildContext context) {
    final d = context.design;
    return GmCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '今日灵机：$teaserLevel',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: d.gold, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          Text(
            '所求何事？',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: d.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            '写下你想问的事（如：彤程新材还能涨吗），今日仅此一次正式求签。',
            style: TextStyle(fontSize: 11, color: d.textMuted, height: 1.4),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            maxLines: 3,
            maxLength: 48,
            style: TextStyle(fontSize: 13, color: d.textPrimary),
            decoration: InputDecoration(
              hintText: '例：这周黄金还能涨吗？',
              hintStyle: TextStyle(fontSize: 12, color: d.textMuted),
              filled: true,
              fillColor: d.chipBg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: d.cardBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: d.cardBorder),
              ),
            ),
          ),
          const Spacer(),
          Center(
            child: Text('🎴', style: TextStyle(fontSize: 48, color: d.gold.withValues(alpha: 0.35))),
          ),
        ],
      ),
    );
  }
}

class _FortuneCard extends StatelessWidget {
  const _FortuneCard({
    required this.header,
    required this.content,
    required this.shake,
    required this.design,
    this.contentOnlyShake = false,
  });

  final FortuneStick header;
  final FortuneStick content;
  final AnimationController shake;
  final AppDesign design;
  final bool contentOnlyShake;

  @override
  Widget build(BuildContext context) {
    final d = design;
    final levelColor = switch (FortuneLevelArt.normalize(header.level)) {
      '上上签' => const Color(0xFFE53935),
      '上签' => design.gold,
      '中上签' => const Color(0xFFFF8F00),
      '中签' => design.textSecondary,
      '中下签' => const Color(0xFF7E57C2),
      '下签' => const Color(0xFF546E7A),
      '下下签' => const Color(0xFF37474F),
      _ => design.textSecondary,
    };

    final headerBlock = Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [levelColor.withValues(alpha: 0.28), levelColor.withValues(alpha: 0.06)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(d.radius)),
      ),
      child: Column(
        children: [
          FortuneLevelArt(level: header.level, size: 64),
          const SizedBox(height: 6),
          Text(
            header.level,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: levelColor,
              letterSpacing: 4,
            ),
          ),
          const SizedBox(height: 2),
          Text(header.title, style: TextStyle(fontSize: 12, color: d.textMuted, letterSpacing: 2)),
        ],
      ),
    );

    final bodyBlock = Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            content.poem,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.55,
              fontWeight: FontWeight.w600,
              color: d.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          if (content.stockInsight.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: d.gold.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: d.gold.withValues(alpha: 0.25)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('自选解读', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: d.gold)),
                  const SizedBox(height: 6),
                  Text(
                    content.stockInsight,
                    style: TextStyle(fontSize: 11, height: 1.45, color: d.textPrimary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: d.chipBg.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: d.cardBorder.withValues(alpha: 0.5)),
            ),
            child: Text(
              content.advice,
              style: TextStyle(fontSize: 11, height: 1.45, color: d.textSecondary),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _LuckyChip(icon: '🎯', label: '贵人股', value: content.luckyStock, color: d.rise),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _LuckyChip(icon: '📜', label: '宜做', value: content.luckyAction, color: d.gold),
              ),
            ],
          ),
        ],
      ),
    );

    Widget card = GmCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          headerBlock,
          if (contentOnlyShake)
            AnimatedBuilder(
              animation: shake,
              builder: (context, child) {
                final t = shake.value;
                final angle = sin(t * pi * 6) * 0.03 * (1 - t);
                return Transform.rotate(angle: angle, child: child);
              },
              child: bodyBlock,
            )
          else
            bodyBlock,
        ],
      ),
    );

    if (!contentOnlyShake) {
      card = AnimatedBuilder(
        animation: shake,
        builder: (context, child) {
          final t = shake.value;
          final angle = sin(t * pi * 6) * 0.04 * (1 - t);
          return Transform.rotate(angle: angle, child: child);
        },
        child: card,
      );
    }

    return card;
  }
}

class _LuckyChip extends StatelessWidget {
  const _LuckyChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final String icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final d = context.design;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$icon $label', style: TextStyle(fontSize: 9, color: d.textMuted)),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
          ),
        ],
      ),
    );
  }
}
