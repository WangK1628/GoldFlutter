import 'package:flutter/material.dart';

import 'package:flutter/services.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';



import '../../core/app_design.dart';

import '../../models/market_models.dart';

import '../../providers/app_providers.dart';

import '../../services/window_layout.dart';

import '../widgets/toast.dart';

import 'chart_cards.dart';



class StockTable extends ConsumerStatefulWidget {

  const StockTable({

    super.key,

    required this.headers,

    required this.selected,

    this.showHeader = true,

    this.showGrid = false,

  });



  final List<String> headers;

  final String selected;

  final bool showHeader;

  final bool showGrid;



  @override

  ConsumerState<StockTable> createState() => _StockTableState();

}



class _StockTableState extends ConsumerState<StockTable> {

  final _hScroll = ScrollController();

  final _vScroll = ScrollController();



  @override

  void dispose() {

    _hScroll.dispose();

    _vScroll.dispose();

    super.dispose();

  }



  double get _tableWidth => WindowLayout.tableContentWidth(widget.headers);



  @override

  Widget build(BuildContext context) {

    final board = ref.watch(marketProvider).stocks;

    final d = context.design;



    if (board.error.isNotEmpty) {

      return Center(

        child: Text(board.error, style: TextStyle(color: d.fall, fontSize: 12)),

      );

    }

    if (board.rows.isEmpty) {

      return Center(child: Text('暂无行情', style: TextStyle(color: d.textMuted)));

    }



    return DecoratedBox(

      decoration: d.cardDecoration(),

      child: LayoutBuilder(

        builder: (context, constraints) {

          return Scrollbar(

            controller: _hScroll,

            thumbVisibility: true,

            child: SingleChildScrollView(

              controller: _hScroll,

              scrollDirection: Axis.horizontal,

              child: SizedBox(

                width: _tableWidth,

                height: constraints.maxHeight,

                child: Column(

                  children: [

                    if (widget.showHeader) _HeaderRow(headers: widget.headers),

                    if (widget.showHeader) Divider(height: 1, color: d.cardBorder),

                    Expanded(

                      child: Scrollbar(

                        controller: _vScroll,

                        thumbVisibility: true,

                        child: ListView.separated(

                          controller: _vScroll,

                          padding: EdgeInsets.zero,

                          itemCount: board.rows.length,

                          separatorBuilder: (_, __) => Divider(height: 1, color: d.cardBorder),

                          itemBuilder: (context, index) {

                            final row = board.rows[index];

                            final code = row.meta.code;

                            return _DataRow(

                              row: row,

                              headers: widget.headers,

                              selected: code == widget.selected,

                              showGrid: widget.showGrid,

                              onTap: () {

                                ref.read(marketProvider.notifier).selectStock(

                                      code == widget.selected ? '' : code,

                                    );

                              },

                              onContext: (pos) => _showMenu(context, pos, code, row),

                            );

                          },

                        ),

                      ),

                    ),

                  ],

                ),

              ),

            ),

          );

        },

      ),

    );

  }



  void _showMenu(BuildContext context, Offset pos, String code, StockRow row) {
    showMenu<String>(

      context: context,

      position: RelativeRect.fromLTRB(pos.dx, pos.dy, pos.dx, pos.dy),

      items: [

        const PopupMenuItem(value: 'detail', child: Text('查看详情')),

        const PopupMenuItem(value: 'copy', child: Text('复制代码')),

        const PopupMenuItem(value: 'remove', child: Text('移除自选')),

      ],

    ).then((action) {

      if (action == null) return;

      switch (action) {

        case 'detail':

          ref.read(marketProvider.notifier).selectStock(code);

        case 'copy':

          Clipboard.setData(ClipboardData(text: code));

          showToast(ref, '已复制 $code');

        case 'remove':

          ref.read(marketProvider.notifier).removeStock(code);

      }

    });

  }

}



class _HeaderRow extends StatelessWidget {

  const _HeaderRow({required this.headers});

  final List<String> headers;



  @override

  Widget build(BuildContext context) {

    final d = context.design;

    return Container(

      height: 34,

      color: d.chipBg,

      child: Row(

        children: [

          for (final h in headers)

            SizedBox(

              width: WindowLayout.columnWidth[h] ?? 48,

              child: Padding(

                padding: const EdgeInsets.symmetric(horizontal: 6),

                child: Align(

                  alignment: Alignment.centerLeft,

                  child: Text(

                    h,

                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: d.textMuted),

                  ),

                ),

              ),

            ),

        ],

      ),

    );

  }

}



class _DataRow extends StatelessWidget {

  const _DataRow({

    required this.row,

    required this.headers,

    required this.selected,

    required this.showGrid,

    required this.onTap,

    required this.onContext,

  });



  final StockRow row;

  final List<String> headers;

  final bool selected;

  final bool showGrid;

  final VoidCallback onTap;

  final void Function(Offset pos) onContext;



  @override

  Widget build(BuildContext context) {

    final d = context.design;

    return Material(

      color: selected ? d.chipSelected : Colors.transparent,

      child: InkWell(

        onTap: onTap,

        onSecondaryTapDown: (details) => onContext(details.globalPosition),

        child: Container(

          decoration: showGrid

              ? BoxDecoration(

                  border: Border(bottom: BorderSide(color: d.cardBorder.withValues(alpha: 0.6))),

                )

              : null,

          height: WindowLayout.tableRowH,

          child: Row(

            children: [

              for (final h in headers)

                SizedBox(

                  width: WindowLayout.columnWidth[h] ?? 48,

                  child: _Cell(row: row, header: h),

                ),

            ],

          ),

        ),

      ),

    );

  }

}



class _Cell extends StatelessWidget {

  const _Cell({required this.row, required this.header});



  final StockRow row;

  final String header;



  static const _all = [

    '代码', '名称', '现价', '涨跌值', '涨跌幅', '买一', '卖一',

    '委比', '成交量', '成交额', '均价', 'K线',

  ];



  @override

  Widget build(BuildContext context) {

    final d = context.design;

    if (header == 'K线' && row.kline != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
        child: Align(
          alignment: Alignment.center,
          child: SizedBox(
            height: 24,
            width: double.infinity,
            child: CustomPaint(
              painter: MiniKlinePainter(
                row.kline!,
                d.delta(row.meta.delta),
                neutral: d.textMuted,
              ),
            ),
          ),
        ),
      );
    }

    final idx = _all.indexOf(header);

    if (idx < 0 || idx >= row.cells.length) return const SizedBox.shrink();

    final text = row.cells[idx];

    final colored = header == '现价' || header == '涨跌幅' || header == '涨跌值';

    return Padding(

      padding: const EdgeInsets.symmetric(horizontal: 6),

      child: Align(

        alignment: Alignment.centerLeft,

        child: Text(

          text,

          style: TextStyle(

            fontSize: 11,

            color: colored ? d.delta(row.meta.delta) : d.textPrimary,

          ),

          overflow: TextOverflow.visible,

          softWrap: false,

        ),

      ),

    );

  }

}


