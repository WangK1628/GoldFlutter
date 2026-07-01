import 'dart:io';

import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import '../../core/app_design.dart';

/// 无边框窗口拖拽区域。
class WindowDragRegion extends StatelessWidget {
  const WindowDragRegion({super.key, required this.child});

  final Widget child;

  static void startDrag() {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      windowManager.startDragging();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onPanStart: (_) => startDrag(),
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
    return Material(
      type: MaterialType.transparency,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(design.radius),
        child: ColoredBox(
          color: design.card,
          child: child,
        ),
      ),
    );
  }
}
