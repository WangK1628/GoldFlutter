import 'dart:ffi';
import 'dart:io';

import 'package:win32/win32.dart';

/// Windows 单实例锁 — 防止重复启动多个窗口。
class SingleInstance {
  static RandomAccessFile? _lock;

  /// 返回 false 表示已有实例在运行（已尝试激活现有窗口）。
  static bool acquire() {
    if (!Platform.isWindows) return true;

    final temp = Platform.environment['TEMP'];
    if (temp == null || temp.isEmpty) return true;

    final lockPath = '$temp${Platform.pathSeparator}GoldMonitor.instance.lock';
    try {
      final file = File(lockPath);
      _lock = file.openSync(mode: FileMode.write);
      _lock!.lockSync(FileLock.exclusive);
      return true;
    } catch (_) {
      _activateExisting();
      return false;
    }
  }

  static void _activateExisting() {
    final cls = TEXT('FLUTTER_RUNNER_WIN32_WINDOW');
    try {
      final hwnd = FindWindow(cls, nullptr);
      if (hwnd == 0) return;
      if (IsIconic(hwnd) != 0) {
        ShowWindow(hwnd, SW_RESTORE);
      } else {
        ShowWindow(hwnd, SW_SHOW);
      }
      SetForegroundWindow(hwnd);
    } finally {
      free(cls);
    }
  }

  static void dispose() {
    try {
      _lock?.closeSync();
    } catch (_) {}
    _lock = null;
  }
}
