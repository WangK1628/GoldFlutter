import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/app_design.dart';
import '../../models/market_models.dart';
import 'gm_card.dart';

/// 品牌/银行金价表 — 内容超出时自动滚动，悬停暂停；滚动条仅悬停时显示。
class AutoScrollPriceTable extends StatefulWidget {
  const AutoScrollPriceTable({
    super.key,
    required this.title,
    required this.items,
    this.maxVisible = 6,
  });

  final String title;
  final List<ShopGoldItem> items;
  final int maxVisible;

  @override
  State<AutoScrollPriceTable> createState() => _AutoScrollPriceTableState();
}

class _AutoScrollPriceTableState extends State<AutoScrollPriceTable> {
  final _scroll = ScrollController();
  Timer? _timer;
  bool _hovering = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startAutoScroll());
  }

  @override
  void didUpdateWidget(AutoScrollPriceTable old) {
    super.didUpdateWidget(old);
    if (old.items.length != widget.items.length) {
      _timer?.cancel();
      WidgetsBinding.instance.addPostFrameCallback((_) => _startAutoScroll());
    }
  }

  void _startAutoScroll() {
    _timer?.cancel();
    if (!_scroll.hasClients || widget.items.length <= widget.maxVisible) return;
    _timer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (_hovering || !_scroll.hasClients) return;
      final max = _scroll.position.maxScrollExtent;
      if (max <= 0) return;
      var next = _scroll.offset + 0.6;
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
    if (widget.items.isEmpty) return const SizedBox.shrink();
    final d = context.design;
    const rowH = 28.0;
    final height = (widget.items.length.clamp(1, widget.maxVisible)) * rowH + 36;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GmCard(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: d.textPrimary)),
            const SizedBox(height: 6),
            SizedBox(
              height: height - 28,
              child: ScrollConfiguration(
                behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
                child: Scrollbar(
                  controller: _scroll,
                  thumbVisibility: _hovering,
                  trackVisibility: _hovering,
                  child: ListView.builder(
                    controller: _scroll,
                    padding: EdgeInsets.zero,
                    itemCount: widget.items.length,
                    itemExtent: rowH,
                    itemBuilder: (_, i) {
                      final e = widget.items[i];
                      return Row(
                        children: [
                          Expanded(
                            child: Text(e.name, style: TextStyle(fontSize: 12, color: d.textPrimary)),
                          ),
                          Text(e.price, style: TextStyle(fontSize: 12, color: d.gold, fontWeight: FontWeight.w500)),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
