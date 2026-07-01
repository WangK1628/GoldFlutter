import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

import '../models/market_models.dart';
import '../providers/app_providers.dart';
import '../services/autostart_service.dart';
import '../services/window_controller.dart';

class DesktopBootstrap with WindowListener, TrayListener {
  DesktopBootstrap(this.ref);

  final WidgetRef ref;

  Future<void> init() async {
    if (!Platform.isWindows && !Platform.isLinux && !Platform.isMacOS) return;
    await AutostartService.init();
    AutostartService.setAppUserModelId();
    await TrayService.init();
    windowManager.addListener(this);
    trayManager.addListener(this);
    await windowManager.setPreventClose(true);
    if (ref.read(configProvider).startOnBoot) {
      await AutostartService.setEnabled(true);
    }
    await TrayService.syncShowLabel(ref.read(windowControllerProvider));
  }

  void dispose() {
    windowManager.removeListener(this);
    trayManager.removeListener(this);
  }

  @override
  void onWindowClose() {
    ref.read(windowControllerProvider.notifier).onCloseRequested();
  }

  @override
  void onWindowFocus() {
    ref.read(windowControllerProvider.notifier).onWindowFocusChanged(true);
  }

  @override
  void onWindowBlur() {
    ref.read(windowControllerProvider.notifier).onWindowFocusChanged(false);
  }

  @override
  void onWindowMoved() {
    final mode = ref.read(windowControllerProvider);
    if (mode == ViewMode.normal) {
      ref.read(windowControllerProvider.notifier).saveGeometry();
    }
  }

  @override
  void onTrayIconMouseDown() {
    ref.read(windowControllerProvider.notifier).showMainGold();
  }

  @override
  void onTrayIconRightMouseDown() {
    trayManager.popUpContextMenu();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    final ctrl = ref.read(windowControllerProvider.notifier);
    switch (menuItem.key) {
      case 'show':
        ctrl.showMainGold();
      case 'mini':
        ctrl.enterMini();
      case 'refresh':
        ref.read(marketProvider.notifier).refreshAll();
      case 'settings':
        ctrl.requestSettings();
      case 'autostart':
        _toggleAutostart();
      case 'quit':
        _quit();
    }
  }

  Future<void> _toggleAutostart() async {
    final enabled = await AutostartService.isEnabled();
    final next = !enabled;
    await AutostartService.setEnabled(next);
    ref.read(configProvider.notifier).update((c) {
      c.startOnBoot = next;
      return c;
    });
    await ref.read(configProvider.notifier).save();
    await TrayService.syncShowLabel(ref.read(windowControllerProvider));
  }

  Future<void> _quit() async {
    await ref.read(windowControllerProvider.notifier).saveGeometry();
    await TrayService.destroy();
    await windowManager.destroy();
  }
}
