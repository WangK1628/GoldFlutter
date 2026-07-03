import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' show Material, MaterialType;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import '../../app/desktop_bootstrap.dart';
import '../../core/app_design.dart';
import '../../models/market_models.dart';
import '../../providers/app_providers.dart';
import '../../providers/fortune_provider.dart';
import '../../providers/millionaire_provider.dart';
import '../../services/window_controller.dart';
import '../../services/window_layout.dart';
import '../widgets/mini_view.dart';
import '../widgets/nav_bar.dart';
import '../widgets/status_bar.dart';
import '../widgets/notification_toast.dart';
import '../widgets/toast.dart';
import '../widgets/window_chrome.dart';
import 'gold_tab.dart';
import 'fortune_tab.dart';
import 'settings_dialog.dart';
import 'stock_tab.dart';

class ShellScreen extends ConsumerStatefulWidget {
  const ShellScreen({super.key});

  @override
  ConsumerState<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends ConsumerState<ShellScreen> {
  DesktopBootstrap? _bootstrap;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(_bootstrapApp);
  }

  Future<void> _bootstrapApp() async {
    try {
      await ref.read(configProvider.notifier).load();
      final cfg = ref.read(configProvider);
      if (cfg.lastTab == 'stock' && cfg.stockBoard) {
        ref.read(marketProvider.notifier).setTab(MainTab.stock);
      } else if (cfg.lastTab == 'fortune') {
        ref.read(marketProvider.notifier).setTab(MainTab.fortune);
      }
      if (cfg.selectedCode.isNotEmpty) {
        await ref.read(marketProvider.notifier).selectStock(cfg.selectedCode);
      }

      if (mounted) setState(() => _ready = true);

      await ref.read(marketProvider.notifier).init();
      await ref.read(fortuneUiProvider.notifier).load();

      _bootstrap = DesktopBootstrap(ref);
      await _bootstrap!.init();
      await ref.read(windowControllerProvider.notifier).restoreGeometry(cfg);
      final initial = ref.read(windowControllerProvider.notifier).initialMode(cfg);
      await ref.read(windowControllerProvider.notifier).applyMode(initial);
    } catch (_) {
      if (mounted) setState(() => _ready = true);
    }
  }

  @override
  void dispose() {
    _bootstrap?.dispose();
    super.dispose();
  }

  void _syncNormalSize() {
    if (ref.read(windowControllerProvider) != ViewMode.normal) return;
    if (ref.read(settingsDialogActiveProvider)) return;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final state = ref.read(marketProvider);
      final cfg = ref.read(configProvider);
      final size = WindowLayout.fitSize(tab: state.activeTab, cfg: cfg, state: state);
      await windowManager.setSize(size);
    });
  }

  void _syncMiniSize() {
    if (ref.read(windowControllerProvider) != ViewMode.mini) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(windowControllerProvider.notifier).syncMiniSize();
    });
  }

  Future<void> _openSettings() async {
    if (ref.read(windowControllerProvider) == ViewMode.mini) {
      await ref.read(windowControllerProvider.notifier).showNormal();
      if (!mounted) return;
    }
    final ctrl = ref.read(windowControllerProvider.notifier);
    ref.read(settingsDialogActiveProvider.notifier).state = true;
    try {
      await ctrl.prepareForSettings();
      if (!mounted) return;
      ctrl.yieldSmartLayer('settings');
      await showDialog<void>(
        context: context,
        barrierDismissible: true,
        barrierColor: Colors.black.withValues(alpha: 0.45),
        builder: (_) => const SettingsDialog(),
      );
    } finally {
      ref.read(settingsDialogActiveProvider.notifier).state = false;
      if (mounted) {
        await ctrl.restoreAfterSettings();
        await ctrl.resumeSmartLayer('settings');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = context.design;

    ref.listen(marketProvider, (_, __) {
      _syncNormalSize();
      _syncMiniSize();
    });
    ref.listen(configProvider, (prev, next) {
      _syncNormalSize();
      if (prev?.bossKeyEnabled != next.bossKeyEnabled) {
        _bootstrap?.restartHotkey();
      }
      if (prev?.alwaysOnTop != next.alwaysOnTop ||
          prev?.hideFromTaskbar != next.hideFromTaskbar ||
          prev?.opacity != next.opacity ||
          prev?.themePreset != next.themePreset ||
          prev?.theme != next.theme) {
        ref.read(windowControllerProvider.notifier).applyWindowFlags(next);
      }
    });
    ref.listen(windowControllerProvider, (_, mode) {
      ref.read(marketProvider.notifier).onViewModeChanged(mode);
      if (mode == ViewMode.normal) _syncNormalSize();
      if (mode == ViewMode.mini) _syncMiniSize();
    });

    ref.listen(settingsOpenProvider, (prev, open) {
      if (open == true) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(settingsOpenProvider.notifier).state = false;
          _openSettings();
        });
      }
    });

    ref.listen(marketProvider.select((s) => s.activeTab), (prev, next) {
      if (prev == MainTab.stock && next != MainTab.stock) {
        ref.read(millionaireProvider.notifier).resetSession();
      }
      if (next == MainTab.stock) {
        ref.read(millionaireProvider.notifier).ensureLoaded();
      }
      if (next == MainTab.fortune) {
        ref.read(fortuneUiProvider.notifier).load();
      }
    });

    if (!_ready) {
      return RoundedWindowShell(
        design: d,
        child: const Center(child: ProgressRing()),
      );
    }

    final mode = ref.watch(windowControllerProvider);
    final toast = ref.watch(toastMessageProvider);

    if (mode == ViewMode.mini) {
      return Stack(
        clipBehavior: Clip.none,
        children: [
          const Material(type: MaterialType.transparency, child: MiniView()),
          const NotificationOverlay(),
          if (toast != null) _Toast(text: toast),
        ],
      );
    }

    if (mode == ViewMode.hidden) {
      return const SizedBox.shrink();
    }

    final state = ref.watch(marketProvider);
    final tabIndex = switch (state.activeTab) {
      MainTab.gold => 0,
      MainTab.stock => 1,
      MainTab.fortune => 2,
    };

    return Stack(
      children: [
        RoundedWindowShell(
          design: d,
          child: Column(
            children: [
              NavBar(onSettings: _openSettings),
              Expanded(
                child: IndexedStack(
                  index: tabIndex,
                  children: const [GoldTab(), StockTab(), FortuneTab()],
                ),
              ),
              const StatusBar(),
            ],
          ),
        ),
        if (toast != null) _Toast(text: toast),
        const NotificationOverlay(),
      ],
    );
  }
}

class _Toast extends StatelessWidget {
  const _Toast({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final d = context.design;
    return Positioned(
      right: 12,
      top: 48,
      child: Material(
        color: Colors.transparent,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: d.card,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: d.gold.withValues(alpha: 0.55), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(FluentIcons.info, size: 14, color: d.gold),
                const SizedBox(width: 8),
                Text(
                  text,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: d.textPrimary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class GoldMonitorApp extends ConsumerWidget {
  const GoldMonitorApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cfg = ref.watch(configProvider);
    final design = AppDesign.resolve(cfg);
    return FluentApp(
      title: 'Gold Monitor',
      debugShowCheckedModeBanner: false,
      theme: buildFluentTheme(cfg),
      color: Colors.transparent,
      home: DesignScope(
        design: design,
        child: const ShellScreen(),
      ),
    );
  }
}
