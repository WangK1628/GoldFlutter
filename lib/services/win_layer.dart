import 'dart:ffi';
import 'dart:io';

import 'package:win32/win32.dart';

import 'win_mouse.dart';

/// 前台窗口信息，用于判断是否需要让出浮层。
class ForegroundWindowInfo {
  const ForegroundWindowInfo({required this.hwnd, required this.className});

  final int hwnd;
  final String className;
}

/// Windows 窗口层级辅助：识别系统 UI / 截屏工具。
class WinLayer {
  WinLayer._();

  static const _systemClassPrefixes = <String>[
    'Shell_TrayWnd',
    'Shell_SecondaryTrayWnd',
    'NotifyIconOverflowWindow',
    'TopLevelWindowForOverflowXamlIslandWindow',
    'XamlExplorerHostIslandWindow',
    'MultitaskingViewFrame',
    'Windows.UI.Core.CoreWindow',
    'ApplicationFrameWindow',
    'ForegroundStaging',
    'DV2ControlHost',
    'SysShadow',
  ];

  static const _screenshotClassHints = <String>[
    'ScreenClippingHost',
    'SnippingTool',
    'CropOverlayWindow',
    'Screenshot',
    'ScreenSnip',
  ];

  static ForegroundWindowInfo? foregroundInfo() {
    if (!Platform.isWindows) return null;
    final hwnd = GetForegroundWindow();
    if (hwnd == 0) return null;
    return ForegroundWindowInfo(hwnd: hwnd, className: _classNameOf(hwnd));
  }

  static String _classNameOf(int hwnd) {
    final buf = wsalloc(256);
    try {
      GetClassName(hwnd, buf, 256);
      final codes = <int>[];
      final ptr = buf.cast<Uint16>();
      for (var i = 0; i < 256; i++) {
        final unit = ptr[i];
        if (unit == 0) break;
        codes.add(unit);
      }
      return String.fromCharCodes(codes);
    } finally {
      free(buf);
    }
  }

  static bool isOurWindow(int hwnd) => hwnd != 0 && hwnd == WinMouse.appHwnd();

  static bool isScreenshotContext(ForegroundWindowInfo info) {
    final cls = info.className;
    return _screenshotClassHints.any(
      (hint) => cls.contains(hint),
    );
  }

  static bool isSystemUi(ForegroundWindowInfo info) {
    final cls = info.className;
    return _systemClassPrefixes.any(
      (prefix) => cls.startsWith(prefix) || cls.contains(prefix),
    );
  }

  /// 前台窗口属于系统壳层或截屏工具时，应暂时让出浮层。
  static bool shouldYieldTo(ForegroundWindowInfo info) {
    if (isOurWindow(info.hwnd)) return false;
    return isSystemUi(info) || isScreenshotContext(info);
  }

  static String yieldReasonFor(ForegroundWindowInfo info) {
    if (isScreenshotContext(info)) return 'screenshot';
    if (isSystemUi(info)) return 'system';
    return 'transient';
  }
}
