import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:window_manager/window_manager.dart';

import '../../core/app_design.dart';

/// 无边框窗口拖拽 — 与 window_manager 的 DragToMoveArea 一致，仅 onPanStart 触发原生拖动。
/// 不在 onPanEnd 调用 cancelModalDrag，否则会打断 SC_MOVE 模态循环导致抖动。
class WindowDragRegion extends StatelessWidget {
  const WindowDragRegion({super.key, required this.child});

  final Widget child;

  static bool get _canDrag =>
      Platform.isWindows || Platform.isLinux || Platform.isMacOS;

  @override
  Widget build(BuildContext context) {
    if (!_canDrag) return child;
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onPanStart: (_) => windowManager.startDragging(),
      child: child,
    );
  }
}

/// 圆角窗口内容壳 — 窗口背景透明，由 Flutter 裁剪圆角，避免方形棱角。
class RoundedWindowShell extends StatelessWidget {
  const RoundedWindowShell({
    super.key,
    required this.design,
    required this.child,
  });

  final AppDesign design;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(design.radius),
      child: ColoredBox(
        color: design.card,
        child: child,
      ),
    );
  }
}
