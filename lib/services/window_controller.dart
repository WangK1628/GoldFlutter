import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

import '../models/app_config.dart';
import '../models/market_models.dart';
import '../providers/app_providers.dart';
import '../providers/fortune_provider.dart';
import '../services/autostart_service.dart';
import '../services/fortune_service.dart';
import '../services/win_mouse.dart';
import '../services/window_layer_policy.dart';
import '../services/window_layout.dart';
import '../ui/widgets/mini_view.dart';

final settingsOpenProvider = StateProvider<bool>((ref) => false);

/// 设置弹窗已打开 — 阻止主界面按标签页自动缩窗。
final settingsDialogActiveProvider = StateProvider<bool>((ref) => false);

/// 全透明窗口背景 — 圆角由 Flutter ClipRRect 绘制，避免方形棱角。
const _transparent = Color(0x00000000);

class WindowController extends StateNotifier<ViewMode> {
  WindowController(this.ref) : super(ViewMode.normal);

  final Ref ref;
  late final WindowLayerPolicy _layer = WindowLayerPolicy(ref);
  bool _hiding = false;
  Size? _preSettingsSize;

  ViewMode initialMode(AppConfig cfg) {
    if (cfg.startInTray || cfg.startMinimized) return ViewMode.hidden;
    if (cfg.miniMode) return ViewMode.mini;
    return ViewMode.normal;
  }

  Future<void> applyMode(ViewMode mode) async {
    if (state == mode && mode != ViewMode.hidden) {
      if (mode == ViewMode.mini) await _prepareMini();
      if (mode == ViewMode.normal) await _prepareNormal();
      return;
    }

    final prev = state;
    ref.read(configProvider.notifier).update((c) {
      c.miniMode = mode == ViewMode.mini;
      return c;
    });

    if (!Platform.isWindows && !Platform.isLinux && !Platform.isMacOS) {
      state = mode;
      await ref.read(configProvider.notifier).save();
      return;
    }

    final crossTransition =
        prev != ViewMode.hidden && mode != ViewMode.hidden && prev != mode;
    if (crossTransition) {
      WinMouse.prepareForHide();
      await windowManager.hide();
      WinMouse.prepareForHide();
    }

    switch (mode) {
      case ViewMode.hidden:
        await _performHide(updateState: true);
      case ViewMode.normal:
        await _prepareNormal();
        state = mode;
        await windowManager.show();
        await _restoreMouseAfterShow();
        await windowManager.focus();
        await _layer.sync(mode);
      case ViewMode.mini:
        state = mode;
        await WidgetsBinding.instance.endOfFrame;
        await _prepareMini();
        await windowManager.show();
        await _restoreMouseAfterShow();
        await _prepareMini();
        await windowManager.focus();
        await _layer.sync(mode);
    }

    await ref.read(configProvider.notifier).save();
    await TrayService.syncShowLabel(mode);
  }

  Future<void> _prepareNormal() async {
    final market = ref.read(marketProvider);
    final cfg = ref.read(configProvider);
    final size = WindowLayout.fitSize(tab: market.activeTab, cfg: cfg, state: market);

    await windowManager.setMinimumSize(const Size(1, 1));
    await windowManager.setSize(size);
    await windowManager.setBackgroundColor(_transparent);
    await _setWindowShadow(false);
    await windowManager.setOpacity(cfg.opacity);
    await windowManager.setMinimumSize(const Size(WindowLayout.navMinWidth, 260));
  }

  Future<void> _prepareMini() async {
    final market = ref.read(marketProvider);
    FortuneStick? fortune;
    if (market.activeTab == MainTab.fortune) {
      fortune = ref.read(fortuneUiProvider).daily;
    }
    final size = MiniViewLayout.sizeFor(market, fortune: fortune);

    await windowManager.setMinimumSize(const Size(1, 1));
    await windowManager.setSize(size);
    await windowManager.setBackgroundColor(_transparent);
    await _setWindowShadow(false);
    await windowManager.setMinimumSize(size);
  }

  Future<void> _setWindowShadow(bool enabled) async {
    if (Platform.isWindows || Platform.isMacOS) {
      await windowManager.setHasShadow(enabled);
    }
  }

  Future<void> showMainGold() async {
    ref.read(marketProvider.notifier).setTab(MainTab.gold);
    await showNormal();
  }

  Future<void> toggleMain() async {
    if (state == ViewMode.hidden) {
      await applyMode(ViewMode.normal);
    } else if (state == ViewMode.mini) {
      await applyMode(ViewMode.normal);
    } else {
      await hide();
    }
  }

  Future<void> enterMini() => applyMode(ViewMode.mini);
  Future<void> showNormal() => applyMode(ViewMode.normal);

  Future<void> hide() => _performHide(updateState: true);

  Future<void> _performHide({required bool updateState}) async {
    if ((state == ViewMode.hidden && updateState) || _hiding) return;
    _hiding = true;
    try {
      if (updateState) {
        state = ViewMode.hidden;
        ref.read(configProvider.notifier).update((c) {
          c.miniMode = false;
          return c;
        });
      }
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        WinMouse.prepareForHide();
        if (Platform.isWindows) {
          await windowManager.setIgnoreMouseEvents(true);
        }
        await windowManager.setAlwaysOnTop(false);
        await windowManager.blur();
        await windowManager.hide();
        WinMouse.prepareForHide();
      }
      unawaited(ref.read(configProvider.notifier).save());
      unawaited(TrayService.syncShowLabel(ViewMode.hidden));
    } finally {
      _hiding = false;
    }
  }

  Future<void> _restoreMouseAfterShow() async {
    if (!Platform.isWindows) return;
    await windowManager.setIgnoreMouseEvents(false);
    await applyWindowFlags(ref.read(configProvider));
  }

  Future<void> requestSettings() async {
    if (state == ViewMode.mini) {
      await showNormal();
    }
    ref.read(settingsOpenProvider.notifier).state = true;
  }

  /// 窄窗口（黄金/签页）打开设置前临时放大，保证竖排设置页完整显示。
  Future<void> prepareForSettings() async {
    if (!Platform.isWindows && !Platform.isLinux && !Platform.isMacOS) return;
    final size = await windowManager.getSize();
    const minW = WindowLayout.settingsMinWidth;
    const minH = WindowLayout.settingsMinHeight;
    if (size.width >= minW && size.height >= minH) return;
    _preSettingsSize = size;
    await windowManager.setMinimumSize(const Size(1, 1));
    await windowManager.setSize(Size(
      size.width < minW ? minW : size.width,
      size.height < minH ? minH : size.height,
    ));
  }

  Future<void> restoreAfterSettings() async {
    if (_preSettingsSize == null) return;
    if (!Platform.isWindows && !Platform.isLinux && !Platform.isMacOS) {
      _preSettingsSize = null;
      return;
    }
    final target = _preSettingsSize!;
    _preSettingsSize = null;
    await windowManager.setMinimumSize(const Size(1, 1));
    await windowManager.setSize(target);
    if (state == ViewMode.normal) {
      await windowManager.setMinimumSize(const Size(WindowLayout.navMinWidth, 260));
    } else if (state == ViewMode.mini) {
      await _prepareMini();
    }
  }

  Future<void> onCloseRequested() async {
    WinMouse.prepareForHide();
    await Future<void>.delayed(const Duration(milliseconds: 50));
    WinMouse.prepareForHide();
    final cfg = ref.read(configProvider);
    if (cfg.closeHides) {
      await hide();
    } else {
      await TrayService.destroy();
      await windowManager.destroy();
    }
  }

  Future<void> onMinimizeRequested() async {
    final cfg = ref.read(configProvider);
    if (cfg.minimizeToTray) {
      await enterMini();
      return;
    }
    await windowManager.minimize();
  }

  Future<void> saveGeometry() async {
    if (state == ViewMode.mini) return;
    final pos = await windowManager.getPosition();
    final size = await windowManager.getSize();
    ref.read(configProvider.notifier).update((c) {
      c.windowX = pos.dx.round();
      c.windowY = pos.dy.round();
      c.windowWidth = size.width.round();
      c.windowHeight = size.height.round();
      return c;
    });
    await ref.read(configProvider.notifier).save();
  }

  Future<void> restoreGeometry(AppConfig cfg) async {
    if (cfg.windowX >= 0 && cfg.windowY >= 0) {
      await windowManager.setPosition(Offset(cfg.windowX.toDouble(), cfg.windowY.toDouble()));
    }
    await applyWindowFlags(cfg);
  }

  /// 智能浮层同步（兼容旧调用）。
  Future<void> syncAlwaysOnTop({bool? focused}) => _layer.sync(state);

  Future<void> onWindowFocusChanged(bool focused) async {
    await _layer.onFocusChanged(focused, state);
  }

  void yieldSmartLayer(String reason, {Duration? autoResume}) {
    _layer.suspend(reason, autoResume: autoResume);
  }

  Future<void> resumeSmartLayer([String? reason]) => _layer.resume(reason, state);

  void disposeLayerPolicy() => _layer.dispose();

  Future<void> applyWindowFlags(AppConfig cfg) async {
    if (!Platform.isWindows && !Platform.isLinux && !Platform.isMacOS) return;
    await windowManager.setSkipTaskbar(cfg.hideFromTaskbar);
    await windowManager.setOpacity(cfg.opacity);
    await windowManager.setBackgroundColor(_transparent);
    await _setWindowShadow(false);
    await _layer.sync(state);
  }

  Future<void> syncMiniSize() async {
    if (state != ViewMode.mini) return;
    await _prepareMini();
  }
}

final windowControllerProvider =
    StateNotifierProvider<WindowController, ViewMode>((ref) => WindowController(ref));

class TrayService {
  static bool _ready = false;

  static Future<void> init() async {
    if (_ready) return;
    await trayManager.setIcon('assets/app_icon.ico');
    await trayManager.setToolTip('Gold Monitor');
    _ready = true;
    await syncShowLabel(ViewMode.normal);
  }

  static Future<void> syncShowLabel(ViewMode mode) async {
    final enabled = await AutostartService.isEnabled();
    await trayManager.setContextMenu(Menu(
      items: [
        MenuItem(key: 'show', label: '显示主界面'),
        MenuItem(key: 'mini', label: '迷你模式'),
        MenuItem(key: 'refresh', label: '刷新'),
        MenuItem.separator(),
        MenuItem(key: 'settings', label: '设置'),
        MenuItem(key: 'autostart', label: enabled ? '开机启动 ✓' : '开机启动'),
        MenuItem.separator(),
        MenuItem(key: 'quit', label: '退出'),
      ],
    ));
  }

  static Future<void> destroy() async {
    await trayManager.destroy();
  }
}
