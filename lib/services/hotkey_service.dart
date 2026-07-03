import 'dart:async';
import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:flutter/scheduler.dart';
import 'package:win32/win32.dart';

/// 全局老板键（默认 Alt+W）：隐藏 / 唤醒主窗口。
class HotkeyService {
  HotkeyService({this.onToggle});

  static const _hotkeyId = 9001;
  void Function()? onToggle;
  Timer? _poll;
  bool _registered = false;

  void start({bool enabled = true}) {
    if (!Platform.isWindows || !enabled) return;
    stop();
    _register();
    _poll = Timer.periodic(const Duration(milliseconds: 200), (_) => _drainHotkey());
  }

  void stop() {
    _poll?.cancel();
    _poll = null;
    if (Platform.isWindows && _registered) {
      UnregisterHotKey(0, _hotkeyId);
      _registered = false;
    }
  }

  void _register() {
    UnregisterHotKey(0, _hotkeyId);
    final ok = RegisterHotKey(0, _hotkeyId, MOD_ALT, 0x57 /* W */) != 0;
    _registered = ok;
  }

  void _drainHotkey() {
    if (!_registered) {
      _register();
      return;
    }
    final msg = calloc<MSG>();
    try {
      while (PeekMessage(msg, 0, WM_HOTKEY, WM_HOTKEY, PM_REMOVE) != 0) {
        if (msg.ref.message == WM_HOTKEY && msg.ref.wParam == _hotkeyId) {
          final cb = onToggle;
          if (cb != null) {
            SchedulerBinding.instance.scheduleTask(cb, Priority.animation);
          }
        }
      }
    } finally {
      free(msg);
    }
  }
}
