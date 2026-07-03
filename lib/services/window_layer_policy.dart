import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import '../models/market_models.dart';
import '../providers/app_providers.dart';
import 'win_layer.dart';

/// 智能浮层：保持窗口在普通应用之上，但在截屏/任务栏/托盘菜单等场景自动让路。
class WindowLayerPolicy {
  WindowLayerPolicy(this.ref);

  final Ref ref;
  bool _yielded = false;
  String? _yieldReason;
  Timer? _pollTimer;
  Timer? _autoResumeTimer;

  bool get isYielded => _yielded;

  bool wantsSmartFloat(ViewMode mode) {
    if (mode == ViewMode.hidden) return false;
    if (mode == ViewMode.mini) return true;
    return ref.read(configProvider).alwaysOnTop;
  }

  Future<void> sync(ViewMode mode) async {
    if (!Platform.isWindows && !Platform.isLinux && !Platform.isMacOS) return;
    if (!wantsSmartFloat(mode) || _yielded) {
      await windowManager.setAlwaysOnTop(false);
      return;
    }
    await windowManager.setAlwaysOnTop(true);
  }

  /// 主动让出浮层（托盘菜单、设置弹窗等）。
  void suspend(String reason, {Duration? autoResume}) {
    _yielded = true;
    _yieldReason = reason;
    _autoResumeTimer?.cancel();
    unawaited(windowManager.setAlwaysOnTop(false));
    _stopPoll();
    if (autoResume != null) {
      _autoResumeTimer = Timer(autoResume, () => resume(reason));
    }
  }

  /// 恢复浮层；若传入 [reason] 则仅在该原因匹配时恢复。
  Future<void> resume([String? reason, ViewMode? mode]) async {
    if (reason != null && _yieldReason != reason) return;
    _yielded = false;
    _yieldReason = null;
    _autoResumeTimer?.cancel();
    _stopPoll();
    final currentMode = mode;
    if (currentMode != null) {
      await sync(currentMode);
    }
  }

  Future<void> onFocusChanged(bool focused, ViewMode mode) async {
    if (!wantsSmartFloat(mode)) {
      await sync(mode);
      return;
    }
    if (focused) {
      if (_layerYieldReasonIsTransient()) {
        await resume(null, mode);
      }
      await sync(mode);
      return;
    }
    await _handleBlur(mode);
  }

  bool _layerYieldReasonIsTransient() {
    return _yieldReason == 'system' || _yieldReason == 'screenshot';
  }

  Future<void> _handleBlur(ViewMode mode) async {
    if (Platform.isWindows) {
      final fg = WinLayer.foregroundInfo();
      if (fg != null && WinLayer.shouldYieldTo(fg)) {
        suspend(WinLayer.yieldReasonFor(fg));
        _startPoll(mode);
        return;
      }
    }
    // 普通失焦：保持浮层，不被其它应用压下去。
    await sync(mode);
  }

  void _startPoll(ViewMode mode) {
    _stopPoll();
    _pollTimer = Timer.periodic(const Duration(milliseconds: 400), (_) {
      unawaited(_pollYield(mode));
    });
  }

  Future<void> _pollYield(ViewMode mode) async {
    if (!_yielded || !wantsSmartFloat(mode)) {
      _stopPoll();
      return;
    }
    if (!Platform.isWindows) return;

    final fg = WinLayer.foregroundInfo();
    if (fg == null) return;

    if (WinLayer.isOurWindow(fg.hwnd)) {
      await resume(null, mode);
      _stopPoll();
      return;
    }

    if (!WinLayer.shouldYieldTo(fg)) {
      await resume(null, mode);
      _stopPoll();
    }
  }

  void _stopPoll() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  void dispose() {
    _stopPoll();
    _autoResumeTimer?.cancel();
  }
}
