import 'dart:convert' show utf8;

import 'package:charset/charset.dart';

import '../../core/constants.dart';
import '../../models/market_models.dart';
import '../../utils/stock_code.dart';
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
    final rows = <StockRow>[];
    for (final line in _decodeLines(bytes)) {
      if (!line.contains('="')) continue;
      final head = line.split('="')[0].split('_');
      final parts = line.split('="')[1].split(',');
      if (parts.length < 4) continue;
      final code = head.length > 2 ? head[2] : '';
      final parsed = _parseLine(code, parts, shortCode);
      if (parsed != null) rows.add(parsed);
    }
    if (rows.isEmpty) {
      return const StockBoard(error: '暂无行情数据');
    }
    return StockBoard(rows: rows, headers: headers, codesCount: codes.length);
  }

  List<String> _decodeLines(List<int> bytes) {
    final out = <String>[];
    var start = 0;
    for (var i = 0; i < bytes.length; i++) {
      if (bytes[i] == 0x0a) {
        if (i > start) out.add(_decodeLine(bytes.sublist(start, i)));
        start = i + 1;
      }
    }
    if (start < bytes.length) out.add(_decodeLine(bytes.sublist(start)));
    return out;
  }

  String _decodeLine(List<int> line) {
    if (line.isEmpty) return '';
    final head = String.fromCharCodes(line.take(48));
    final hkUs = head.contains('_hk') || head.contains('_gb_');
    try {
      if (hkUs) return utf8.decode(line, allowMalformed: true);
      return gbk.decode(line);
    } catch (_) {
      return utf8.decode(line, allowMalformed: true);
    }
  }

  StockRow? _parseLine(String code, List<String> parts, bool shortCode) {
    final market = marketOfCode(code);
    return switch (market) {
      StockMarket.hk => _parseHk(code, parts, shortCode),
      StockMarket.us => _parseUs(code, parts, shortCode),
      StockMarket.cn => _parseCn(code, parts, shortCode),
    };
  }

  StockRow? _parseCn(String code, List<String> parts, bool shortCode) {
    if (parts.length < 32) return null;
    final name = resolveStockName(code, parts[0]);
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

    return _buildRow(
      code: code,
      market: StockMarket.cn,
      name: name,
      current: current,
      prevClose: prevClose,
      opening: opening,
      high: high,
      low: low,
      dec: dec,
      vol: dealsVol,
      amt: dealsAmt,
      shortCode: shortCode,
    );
  }

  StockRow? _parseHk(String code, List<String> parts, bool shortCode) {
    if (parts.length < 6) return null;
    final name = resolveStockName(code, parts[0]);
    var opening = double.tryParse(parts[1]) ?? 0;
    final prevClose = double.tryParse(parts[2]) ?? 0;
    var current = double.tryParse(parts[3]) ?? 0;
    var high = double.tryParse(parts[4]) ?? 0;
    var low = double.tryParse(parts[5]) ?? 0;
    final vol = parts.length > 12 ? (double.tryParse(parts[12]) ?? 0.0) : 0.0;
    final amt = parts.length > 11 ? (double.tryParse(parts[11]) ?? 0.0) : 0.0;

    if (current == 0) current = prevClose;
    if (opening == 0) opening = current;

    return _buildRow(
      code: code,
      market: StockMarket.hk,
      name: name,
      current: current,
      prevClose: prevClose,
      opening: opening,
      high: high,
      low: low,
      dec: 3,
      vol: vol,
      amt: amt,
      shortCode: shortCode,
    );
  }

  StockRow? _parseUs(String code, List<String> parts, bool shortCode) {
    if (parts.length < 4) return null;
    final name = resolveStockName(code, parts[0]);
    final current = double.tryParse(parts[1]) ?? 0;
    final change = double.tryParse(parts[2]) ?? 0;
    final changePct = double.tryParse(parts[3]) ?? 0;
    final opening = parts.length > 4 ? double.tryParse(parts[4]) ?? current : current;
    final high = parts.length > 5 ? double.tryParse(parts[5]) ?? current : current;
    final low = parts.length > 6 ? double.tryParse(parts[6]) ?? current : current;
    final prevClose = current - change;

    return _buildRow(
      code: code,
      market: StockMarket.us,
      name: name,
      current: current,
      prevClose: prevClose,
      opening: opening,
      high: high,
      low: low,
      dec: 2,
      vol: 0,
      amt: 0,
      shortCode: shortCode,
      changeOverride: change.toDouble(),
      pctOverride: changePct.toDouble(),
    );
  }

  StockRow _buildRow({
    required String code,
    required StockMarket market,
    required String name,
    required double current,
    required double prevClose,
    required double opening,
    required double high,
    required double low,
    required int dec,
    required double vol,
    required double amt,
    required bool shortCode,
    double? changeOverride,
    double? pctOverride,
  }) {
    final change = changeOverride ?? (prevClose > 0 ? current - prevClose : 0.0);
    final changePct = pctOverride ?? (prevClose > 0 ? (current / prevClose - 1) * 100 : 0.0);
    final avg = vol > 0 ? amt / vol : prevClose;

    var arrow = '';
    if (high > low) {
      if (current == high) arrow = '↑';
      if (current == low) arrow = '↓';
    }

    final tag = marketTag(market);
    var displayCode = code;
    if (shortCode) {
      if (code.startsWith('gb_')) {
        displayCode = code.substring(3).toUpperCase();
      } else if (code.length > 2 && RegExp(r'^(sh|sz|bj)').hasMatch(code)) {
        displayCode = code.substring(2);
      } else if (code.startsWith('hk')) {
        displayCode = code.substring(2).toUpperCase();
      }
    }
    displayCode = '$tag·$displayCode';

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
        _fmtVolume(vol),
        _fmtAmount(amt),
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
    if (vol <= 0) return '-';
    if (vol < 1e4) return vol.toStringAsFixed(0);
    if (vol < 1e8) return '${(vol / 1e4).toStringAsFixed(2)}万';
    return '${(vol / 1e8).toStringAsFixed(2)}亿';
  }

  String _fmtAmount(double amt) {
    if (amt <= 0) return '-';
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
        name: stockRowName(row),
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
