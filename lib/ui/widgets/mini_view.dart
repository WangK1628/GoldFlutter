import 'dart:async';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_design.dart';
import '../../models/market_models.dart';
import '../../providers/app_providers.dart';
import '../../providers/fortune_provider.dart';
import '../../services/fortune_service.dart';
import '../../services/window_controller.dart';
import '../../utils/stock_code.dart';
import '../widgets/fortune_level_art.dart';
import 'window_chrome.dart';

class MiniViewLayout {
  static const visibleRows = 3;
  static const rowHeight = 20.0;
  static const hPad = 24.0;
  static const vPad = 14.0;
  static const stockWidth = 238.0;
  static const goldWidth = 168.0;
  static const goldHeight = 62.0;

  static double stockHeight() => vPad + visibleRows * rowHeight + 10;

  static const ballSize = 58.0;

  static Size sizeFor(MarketState state, {FortuneStick? fortune, bool ball = false}) {
    if (ball) return const Size(ballSize, ballSize);
    if (state.activeTab == MainTab.fortune) {
      if (fortune != null) return fortuneSize(fortune);
      return const Size(172, 62);
    }
    if (state.activeTab == MainTab.stock) {
      return Size(stockWidth, stockHeight());
    }
    return const Size(goldWidth, goldHeight);
  }

  static Size fortuneSize(FortuneStick stick) {
    final levelLen = stick.level.length * 15.0;
    final titleLen = stick.title.length * 10.0;
    final textW = levelLen > titleLen ? levelLen : titleLen;
    final w = (54 + textW + 24).clamp(172.0, 238.0);
    final h = stick.title.length > 5 ? 72.0 : 64.0;
    return Size(w, h);
  }
}

class MiniView extends ConsumerStatefulWidget {
  const MiniView({super.key});

  @override
  ConsumerState<MiniView> createState() => _MiniViewState();
}

class _MiniViewState extends ConsumerState<MiniView> {
  double _pillOpacity = 0.92;

  void _restore() => ref.read(windowControllerProvider.notifier).showNormal();

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(marketProvider);
    final cfg = ref.watch(configProvider);
    final fortuneUi = ref.watch(fortuneUiProvider);
    final ball = cfg.miniBall;
    final stockMode = state.activeTab == MainTab.stock;
    final fortuneMode = state.activeTab == MainTab.fortune;
    final d = context.design;
    final fortuneStick = fortuneUi.daily;
    final size = MiniViewLayout.sizeFor(state, fortune: fortuneMode ? fortuneStick : null, ball: ball);

    return SizedBox(
      width: size.width,
      height: size.height,
      child: WindowDragRegion(
        child: GestureDetector(
          onTap: ball ? _restore : null,
          onDoubleTap: ball ? null : _restore,
          behavior: HitTestBehavior.opaque,
          child: MouseRegion(
            onEnter: (_) => setState(() => _pillOpacity = 1.0),
            onExit: (_) => setState(() => _pillOpacity = 0.92),
            cursor: SystemMouseCursors.grab,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 160),
              opacity: _pillOpacity,
              child: ball
                  ? _ballShell(state, fortuneStick, d)
                  : fortuneMode
                      ? _fortuneShell(fortuneStick, d)
                      : stockMode
                          ? _stockShell(state, d)
                          : _goldShell(state, d),
            ),
          ),
        ),
      ),
    );
  }

  /// 当前选中的自选行；未选中时不默认取第一条（避免总显示上证指数）。
  StockRow? _pickStockRow(MarketState state) {
    final sel = state.selectedStock;
    if (sel.isEmpty) return null;
    for (final row in state.stocks.rows) {
      if (row.meta.code == sel) return row;
    }
    return null;
  }

  /// 悬浮球：轻透明小圆，单击恢复主界面。
  Widget _ballShell(MarketState state, FortuneStick? fortune, AppDesign d) {
    final tab = state.activeTab;
    if (tab == MainTab.gold) {
      final price = state.snapshot.cnyPrice;
      return _ballCircle(
        d,
        accent: d.gold,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(FluentIcons.circle_dollar, size: 12, color: d.gold.withValues(alpha: 0.9)),
            const SizedBox(height: 2),
            Text(
              price > 0 ? price.toStringAsFixed(0) : '--',
              style: TextStyle(
                color: d.goldLight,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                height: 1,
                shadows: [Shadow(color: Colors.black.withValues(alpha: 0.9), blurRadius: 6)],
              ),
            ),
          ],
        ),
      );
    }
    if (tab == MainTab.stock) {
      final row = _pickStockRow(state);
      if (row == null) {
        return _ballCircle(
          d,
          accent: d.gold,
          child: Icon(FluentIcons.line_chart, size: 18, color: d.gold),
        );
      }
      final pctI = state.stocks.headers.indexOf('涨跌幅');
      final priceI = state.stocks.headers.indexOf('现价');
      final pct = pctI >= 0 && pctI < row.cells.length ? row.cells[pctI] : '';
      final price = priceI >= 0 && priceI < row.cells.length ? row.cells[priceI] : '';
      final color = pct.startsWith('+') ? d.rise : (pct.startsWith('-') ? d.fall : d.goldLight);
      final name = stockRowName(row);
      return _ballCircle(
        d,
        accent: color,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              pct.isNotEmpty ? pct.replaceAll('%', '') : '--',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: color,
                height: 1,
                shadows: _miniTextShadow(),
              ),
            ),
            const SizedBox(height: 1),
            Text(
              name.length > 3 ? name.substring(0, 3) : name,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.95),
                height: 1,
                shadows: _miniTextShadow(),
              ),
            ),
            if (price.isNotEmpty)
              Text(
                price.replaceAll(RegExp(r'[↑↓]'), ''),
                style: TextStyle(
                  fontSize: 8,
                  color: Colors.white.withValues(alpha: 0.88),
                  height: 1.1,
                  shadows: _miniTextShadow(),
                ),
              ),
          ],
        ),
      );
    }
    final level = fortune?.level ?? '签';
    return _ballCircle(
      d,
      accent: d.gold,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('财', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: d.gold, height: 1)),
          Text(
            level.length > 2 ? level.substring(0, 2) : level,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white.withValues(alpha: 0.85), height: 1.1),
          ),
        ],
      ),
    );
  }

  List<Shadow> _miniTextShadow() => [
        Shadow(color: Colors.black.withValues(alpha: 0.85), blurRadius: 5),
        Shadow(color: Colors.black.withValues(alpha: 0.55), blurRadius: 2),
      ];

  Widget _ballCircle(AppDesign d, {required Widget child, required Color accent}) {
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: accent.withValues(alpha: 0.1),
        border: Border.all(color: accent.withValues(alpha: 0.5), width: 1.0),
      ),
      child: Center(child: child),
    );
  }

  Widget _fortuneShell(FortuneStick? stick, AppDesign d) {
    if (stick == null) {
      return Center(
        child: Text(
          '财神签',
          style: TextStyle(
            color: d.gold,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            shadows: [Shadow(color: Colors.black.withValues(alpha: 0.8), blurRadius: 6)],
          ),
        ),
      );
    }
    final levelColor = switch (FortuneLevelArt.normalize(stick.level)) {
      '上上签' => const Color(0xFFE53935),
      '上签' => d.gold,
      '中上签' => const Color(0xFFFF8F00),
      '中下签' => const Color(0xFF7E57C2),
      '下签' || '下下签' => const Color(0xFF546E7A),
      _ => d.textSecondary,
    };
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Row(
        children: [
          FortuneLevelArt(level: stick.level, size: 38),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stick.level,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: levelColor,
                    height: 1.1,
                    shadows: _miniTextShadow(),
                  ),
                ),
                if (stick.title.isNotEmpty)
                  Text(
                    stick.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.92),
                      height: 1.15,
                      shadows: _miniTextShadow(),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 金价迷你：透明底，仅保留价格文字。
  Widget _goldShell(MarketState state, AppDesign d) {
    final price = state.snapshot.cnyPrice;
    return Center(
      child: Text(
        price > 0 ? price.toStringAsFixed(2) : '--',
        style: TextStyle(
          color: d.goldLight,
          fontSize: 28,
          fontWeight: FontWeight.w800,
          height: 1.05,
          shadows: [
            Shadow(color: Colors.black.withValues(alpha: 0.85), blurRadius: 8),
            Shadow(color: d.gold.withValues(alpha: 0.65), blurRadius: 3),
          ],
        ),
      ),
    );
  }

  /// 自选迷你：有选中时只显示该股；否则滚动播报。
  Widget _stockShell(MarketState state, AppDesign d) {
    final selected = _pickStockRow(state);
    if (selected != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: _MiniStockLine(row: selected, headers: state.stocks.headers, design: d),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: _MiniStockTicker(state: state, design: d),
    );
  }
}

class _MiniStockLine extends StatelessWidget {
  const _MiniStockLine({required this.row, required this.headers, required this.design});

  final StockRow row;
  final List<String> headers;
  final AppDesign design;

  @override
  Widget build(BuildContext context) {
    final d = design;
    final priceI = headers.indexOf('现价');
    final pctI = headers.indexOf('涨跌幅');
    final name = stockRowName(row);
    final price = priceI >= 0 && priceI < row.cells.length ? row.cells[priceI] : '';
    final pct = pctI >= 0 && pctI < row.cells.length ? row.cells[pctI] : '';
    final pctColor = pct.startsWith('+') ? d.rise : (pct.startsWith('-') ? d.fall : Colors.white.withValues(alpha: 0.95));
    final shadow = [
      Shadow(color: Colors.black.withValues(alpha: 0.9), blurRadius: 6),
      Shadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 2),
    ];

    return Center(
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: name,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white, shadows: shadow),
            ),
            const TextSpan(text: '  '),
            TextSpan(
              text: price.replaceAll(RegExp(r'[↑↓]'), ''),
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: d.goldLight, shadows: shadow),
            ),
            const TextSpan(text: '  '),
            TextSpan(
              text: pct,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: pctColor, shadows: shadow),
            ),
          ],
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _MiniStockTicker extends StatefulWidget {
  const _MiniStockTicker({required this.state, required this.design});

  final MarketState state;
  final AppDesign design;

  @override
  State<_MiniStockTicker> createState() => _MiniStockTickerState();
}

class _MiniStockTickerState extends State<_MiniStockTicker> {
  final _scroll = ScrollController();
  Timer? _timer;
  bool _hovering = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startScroll());
  }

  @override
  void didUpdateWidget(_MiniStockTicker old) {
    super.didUpdateWidget(old);
    if (old.state.stocks.rows.length != widget.state.stocks.rows.length) {
      _timer?.cancel();
      WidgetsBinding.instance.addPostFrameCallback((_) => _startScroll());
    }
  }

  void _startScroll() {
    _timer?.cancel();
    if (!_scroll.hasClients) return;
    final rows = widget.state.stocks.rows;
    if (rows.length <= MiniViewLayout.visibleRows) return;

    _timer = Timer.periodic(const Duration(milliseconds: 80), (_) {
      if (_hovering || !_scroll.hasClients) return;
      final max = _scroll.position.maxScrollExtent;
      if (max <= 0) return;
      var next = _scroll.offset + 0.55;
      if (next >= max) next = 0;
      _scroll.jumpTo(next);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final board = widget.state.stocks;
    final d = widget.design;

    if (board.error.isNotEmpty) {
      return Text(
        board.error.substring(0, board.error.length.clamp(0, 20)),
        style: TextStyle(color: d.textSecondary, fontSize: 11),
      );
    }
    if (board.rows.isEmpty) {
      return Text('暂无自选', style: TextStyle(color: d.textSecondary, fontSize: 11));
    }

    final headers = board.headers;
    final nameI = headers.indexOf('名称');
    final priceI = headers.indexOf('现价');
    final pctI = headers.indexOf('涨跌幅');

    final viewH = MiniViewLayout.visibleRows * MiniViewLayout.rowHeight;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: SizedBox(
        height: viewH,
        child: ListView.builder(
          controller: _scroll,
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: board.rows.length,
          itemExtent: MiniViewLayout.rowHeight,
          itemBuilder: (_, i) {
            final row = board.rows[i];
            final nameRaw = nameI >= 0 && nameI < row.cells.length ? stockRowName(row) : '';
            final name = nameRaw.length > 6 ? nameRaw.substring(0, 6) : nameRaw;
            final price = priceI >= 0 && priceI < row.cells.length ? row.cells[priceI] : '';
            final pct = pctI >= 0 && pctI < row.cells.length ? row.cells[pctI] : '';
            return Text(
              '$name  $price  $pct'.trim(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _lineColor(d, pct),
                height: 1.2,
                shadows: [
                  Shadow(color: Colors.black.withValues(alpha: 0.9), blurRadius: 6),
                  Shadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 2),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Color _lineColor(AppDesign d, String pct) {
    if (pct.startsWith('+')) return d.rise;
    if (pct.startsWith('-')) return d.fall;
    return Colors.white.withValues(alpha: 0.95);
  }
}
