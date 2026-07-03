import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_design.dart';
import '../../models/market_models.dart';
import '../../providers/app_providers.dart';
import '../../services/window_controller.dart';
import '../../services/win_mouse.dart';
import '../../services/window_layout.dart';
import '../screens/gold_expand_page.dart';
import '../screens/stock_expand_page.dart';
import 'window_chrome.dart';

class NavBar extends ConsumerStatefulWidget {
  const NavBar({super.key, this.onSettings});

  final VoidCallback? onSettings;

  @override
  ConsumerState<NavBar> createState() => _NavBarState();
}

class _NavBarState extends ConsumerState<NavBar> {
  DateTime? _lastTap;

  void _onNavDoubleTap() {
    final now = DateTime.now();
    if (_lastTap != null && now.difference(_lastTap!) < const Duration(milliseconds: 350)) {
      ref.read(windowControllerProvider.notifier).onMinimizeRequested();
      _lastTap = null;
      return;
    }
    _lastTap = now;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(marketProvider);
    final cfg = ref.watch(configProvider);
    final d = context.design;

    return Container(
      height: WindowLayout.navHeight,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: d.navDecoration(),
      child: Row(
        children: [
          Expanded(
            child: WindowDragRegion(
              child: GestureDetector(
                onDoubleTap: _onNavDoubleTap,
                behavior: HitTestBehavior.translucent,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(FluentIcons.circle_dollar, color: d.navAccent, size: 15),
                        const SizedBox(width: 8),
                        _tabGroup(
                          ref,
                          d,
                          '黄金',
                          MainTab.gold,
                          state.activeTab,
                          () => GoldExpandPage.open(context),
                        ),
                        if (cfg.stockBoard) ...[
                          const SizedBox(width: 8),
                          _tabGroup(
                            ref,
                            d,
                            '自选 ${state.stocks.codesCount}',
                            MainTab.stock,
                            state.activeTab,
                            () => StockExpandPage.open(context),
                          ),
                        ],
                        const SizedBox(width: 8),
                        _tab(ref, d, '财神签', MainTab.fortune, state.activeTab),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          _iconBtn(FluentIcons.refresh, '刷新', () => ref.read(marketProvider.notifier).refreshAll()),
          _iconBtn(FluentIcons.settings, '设置', widget.onSettings),
          _iconBtn(FluentIcons.mini_contract, '迷你模式', () => ref.read(windowControllerProvider.notifier).enterMini()),
          _iconBtn(FluentIcons.circle_ring, '悬浮球', () => ref.read(windowControllerProvider.notifier).enterBall()),
          _iconBtn(FluentIcons.chrome_minimize, '最小化', () => ref.read(windowControllerProvider.notifier).onMinimizeRequested()),
          _iconBtn(FluentIcons.chrome_close, '关闭', () {
            WinMouse.prepareForHide();
            ref.read(windowControllerProvider.notifier).onCloseRequested();
          }),
        ],
      ),
    );
  }

  Widget _tabGroup(
    WidgetRef ref,
    AppDesign d,
    String label,
    MainTab tab,
    MainTab active,
    VoidCallback onExpand,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _tab(ref, d, label, tab, active),
        _plusBtn(onExpand),
      ],
    );
  }

  Widget _plusBtn(VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.only(left: 3),
      child: Tooltip(
        message: '扩展视图',
        child: SizedBox(
          width: 20,
          height: 20,
          child: Button(
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.all(Colors.white.withValues(alpha: 0.14)),
              padding: WidgetStateProperty.all(EdgeInsets.zero),
              shape: WidgetStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(4))),
            ),
            onPressed: onPressed,
            child: Text(
              '+',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.white.withValues(alpha: 0.95),
                height: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _iconBtn(IconData icon, String tip, VoidCallback? onPressed) {
    return Tooltip(
      message: tip,
      child: SizedBox(
        width: 26,
        height: 26,
        child: IconButton(
          icon: Icon(icon, size: 14, color: Colors.white.withValues(alpha: 0.9)),
          onPressed: onPressed,
          style: ButtonStyle(
            padding: WidgetStateProperty.all(EdgeInsets.zero),
            backgroundColor: WidgetStateProperty.all(Colors.transparent),
          ),
        ),
      ),
    );
  }

  Widget _tab(WidgetRef ref, AppDesign d, String label, MainTab tab, MainTab active) {
    final selected = active == tab;
    return Button(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.all(
          selected ? Colors.white.withValues(alpha: 0.95) : Colors.white.withValues(alpha: 0.1),
        ),
        padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 10, vertical: 5)),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
      ),
      onPressed: () => ref.read(marketProvider.notifier).setTab(tab),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: selected ? d.gold : Colors.white.withValues(alpha: 0.92),
        ),
      ),
    );
  }
}
