import 'dart:ffi';
import 'dart:io';

import 'package:win32/win32.dart';

/// Windows 窗口/鼠标原生操作。
class WinMouse {
  static int _hwnd = 0;

  static int appHwnd() {
    if (_hwnd != 0 && IsWindow(_hwnd) != 0) return _hwnd;
    final cls = TEXT('FLUTTER_RUNNER_WIN32_WINDOW');
    try {
      _hwnd = FindWindow(cls, nullptr);
      return _hwnd;
    } finally {
      free(cls);
    }
  }

  /// 关闭/隐藏前调用：结束模态拖动并彻底释放鼠标捕获。
  static void prepareForHide() {
    if (!Platform.isWindows) return;
    final hwnd = appHwnd();
    if (hwnd != 0) {
      SendMessage(hwnd, WM_CANCELMODE, 0, 0);
      PostMessage(hwnd, WM_LBUTTONUP, 0, 0);
    }
    _synthesizeLeftButtonUp();
    releaseCapture();
  }

  /// 结束 SC_MOVE 模态拖动并释放鼠标捕获。
  static void cancelModalDrag() => prepareForHide();

  /// 在系统层发送左键抬起，防止隐藏窗口后全局鼠标失效。
  static void _synthesizeLeftButtonUp() {
    if (!Platform.isWindows) return;
    PostMessage(HWND_DESKTOP, WM_LBUTTONUP, 0, 0);
  }

  /// 强制释放系统鼠标捕获。
  static void releaseCapture() {
    if (!Platform.isWindows) return;

    var capture = GetCapture();
    var guard = 0;
    while (capture != 0 && guard < 8) {
      SendMessage(capture, WM_CANCELMODE, 0, 0);
      PostMessage(capture, WM_LBUTTONUP, 0, 0);
      ReleaseCapture();
      capture = GetCapture();
      guard++;
    }
    ReleaseCapture();
  }
}
