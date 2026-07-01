import 'package:charset/charset.dart';

import '../../core/constants.dart';
import '../../models/market_models.dart';
import 'api_client.dart';

class StockApi {
  StockApi(this._client);
  final ApiClient _client;

  Future<StockBoard> fetchBoard({
    required List<String> codes,
    required List<String> headers,
    bool shortCode = false,
  }) async {
    if (codes.isEmpty) {
      return const StockBoard(error: '请添加股票代码');
    }
    final label = codes.join(',');
    final bytes = await _client.getBytes(
      'https://hq.sinajs.cn/list=$label',
      headers: {'Referer': AppConstants.sinaReferer},
    );
    final text = gbk.decode(bytes);
    final rows = <StockRow>[];
    for (final line in text.split('\n')) {
      if (!line.contains('="')) continue;
      final head = line.split('="')[0].split('_');
      final parts = line.split('="')[1].split(',');
      if (parts.length < 32) continue;
      final code = head.length > 2 ? head[2] : '';
      final parsed = _parseLine(code, parts, shortCode);
      if (parsed != null) rows.add(parsed);
    }
    if (rows.isEmpty) {
      return const StockBoard(error: '暂无行情数据');
    }
    return StockBoard(rows: rows, headers: headers, codesCount: codes.length);
  }

  StockRow? _parseLine(String code, List<String> parts, bool shortCode) {
    final name = parts[0];
    var opening = double.tryParse(parts[1]) ?? 0;
    final prevClose = double.tryParse(parts[2]) ?? 0;
    var current = double.tryParse(parts[3]) ?? 0;
    var high = double.tryParse(parts[4]) ?? 0;
    var low = double.tryParse(parts[5]) ?? 0;
    final dealsVol = double.tryParse(parts[8]) ?? 0;
    final dealsAmt = double.tryParse(parts[9]) ?? 0;

    final etf = code.length > 2 && (code[2] == '1' || code[2] == '5');
    final dec = etf ? 3 : 2;

    if (current == 0) current = prevClose;
    if (opening == 0) {
      opening = current;
      high = current;
      low = current;
    }

    final change = prevClose > 0 ? current - prevClose : 0.0;
    final changePct = prevClose > 0 ? (current / prevClose - 1) * 100 : 0.0;
    final avg = dealsVol > 0 ? dealsAmt / dealsVol : prevClose;

    var arrow = '';
    if (high > low) {
      if (current == high) arrow = '↑';
      if (current == low) arrow = '↓';
    }

    final displayCode = shortCode && code.length > 2 ? code.substring(2) : code;
    return StockRow(
      cells: [
        displayCode,
        name,
        '${_fmt(current, dec)}$arrow',
        '${change >= 0 ? '+' : ''}${_fmt(change, dec)}',
        '${changePct >= 0 ? '+' : ''}${changePct.toStringAsFixed(2)}%',
        '-',
        '-',
        '0.00%',
        _fmtVolume(dealsVol),
        _fmtAmount(dealsAmt),
        _fmt(avg, dec),
        '',
      ],
      meta: StockRowMeta(
        code: code,
        delta: change > 0 ? 1 : (change < 0 ? -1 : 0),
      ),
      kline: StockKlineData(
        open: opening,
        close: current,
        high: high,
        low: low,
        prevClose: prevClose,
      ),
    );
  }

  String _fmt(double v, int dec) => v.toStringAsFixed(dec);

  String _fmtVolume(double vol) {
    if (vol < 1e4) return vol.toStringAsFixed(0);
    if (vol < 1e8) return '${(vol / 1e4).toStringAsFixed(2)}万';
    return '${(vol / 1e8).toStringAsFixed(2)}亿';
  }

  String _fmtAmount(double amt) {
    if (amt < 1e8) return '${(amt / 1e4).toStringAsFixed(2)}万';
    if (amt < 1e12) return '${(amt / 1e8).toStringAsFixed(2)}亿';
    return '${(amt / 1e12).toStringAsFixed(2)}万亿';
  }
}

StockDetail? findStockDetail(StockBoard board, String code) {
  for (final row in board.rows) {
    if (row.meta.code == code && row.kline != null) {
      final k = row.kline!;
      final change = k.prevClose > 0 ? k.close - k.prevClose : 0.0;
      final pct = k.prevClose > 0 ? (k.close / k.prevClose - 1) * 100 : 0.0;
      return StockDetail(
        code: code,
        name: row.cells.length > 1 ? row.cells[1] : code,
        price: k.close,
        change: change,
        changePct: pct,
        open: k.open,
        high: k.high,
        low: k.low,
        prevClose: k.prevClose,
      );
    }
  }
  return null;
}
