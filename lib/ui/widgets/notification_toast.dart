import 'dart:async';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' show Material, MaterialType;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_design.dart';

enum NotificationKind { info, alert, success }

class AppNotification {
  const AppNotification({
    required this.title,
    required this.body,
    this.kind = NotificationKind.info,
    this.duration = const Duration(seconds: 4),
  });

  final String title;
  final String body;
  final NotificationKind kind;
  final Duration duration;
}

class NotificationQueue extends StateNotifier<List<AppNotification>> {
  NotificationQueue() : super(const []);

  void push(AppNotification n) {
    state = [...state, n];
    Future.delayed(n.duration, () {
      if (state.isNotEmpty && state.last == n) {
        state = state.where((x) => x != n).toList();
      } else {
        state = state.where((x) => x != n).toList();
      }
    });
  }

  void dismiss(AppNotification n) {
    state = state.where((x) => x != n).toList();
  }
}

final notificationQueueProvider =
    StateNotifierProvider<NotificationQueue, List<AppNotification>>((ref) => NotificationQueue());

/// 升级版桌面气泡通知层。
class NotificationOverlay extends ConsumerWidget {
  const NotificationOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(notificationQueueProvider);
    if (items.isEmpty) return const SizedBox.shrink();

    final d = context.design;
    final n = items.last;

    return Positioned(
      right: 14,
      top: 52,
      child: Material(
        type: MaterialType.transparency,
        child: TweenAnimationBuilder<double>(
          key: ValueKey('${n.title}${n.body}'),
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          builder: (_, t, child) => Transform.translate(
            offset: Offset(24 * (1 - t), 0),
            child: Opacity(opacity: t, child: child),
          ),
          child: _BubbleCard(
            notification: n,
            design: d,
            onClose: () => ref.read(notificationQueueProvider.notifier).dismiss(n),
          ),
        ),
      ),
    );
  }
}

class _BubbleCard extends StatelessWidget {
  const _BubbleCard({
    required this.notification,
    required this.design,
    required this.onClose,
  });

  final AppNotification notification;
  final AppDesign design;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final (icon, accent) = switch (notification.kind) {
      NotificationKind.alert => (FluentIcons.ringer, design.gold),
      NotificationKind.success => (FluentIcons.check_mark, const Color(0xFF43A047)),
      NotificationKind.info => (FluentIcons.info, design.navAccent),
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: [
            design.card.withValues(alpha: 0.98),
            design.card.withValues(alpha: 0.92),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: accent.withValues(alpha: 0.55), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: accent.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: accent),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: design.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.body,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.35,
                        color: design.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(FluentIcons.cancel, size: 12, color: design.textMuted),
                onPressed: onClose,
                style: ButtonStyle(padding: WidgetStateProperty.all(EdgeInsets.zero)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
