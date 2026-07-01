import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../core/constants.dart';
import '../../models/app_config.dart';
import '../../models/market_models.dart';

class ConfigStore {
  AppConfig _config = AppConfig();
  AppConfig get config => _config;

  Future<Directory> appDir() => _appDir();

  Future<File> _configFile() async {
    final dir = await _appDir();
    return File('${dir.path}/gold_config.json');
  }

  Future<Directory> _appDir() async {
    if (Platform.isWindows) {
      final appData = Platform.environment['APPDATA'];
      if (appData != null) {
        final dir = Directory('$appData/GoldMonitor');
        if (!await dir.exists()) await dir.create(recursive: true);
        return dir;
      }
    }
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/GoldMonitor');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<void> load() async {
    final file = await _configFile();
    if (!await file.exists()) {
      _config = AppConfig(
        alerts: [
          AlertRule(price: 860, direction: 'below', note: '下跌预警'),
          AlertRule(price: 900, direction: 'above', note: '上涨预警'),
        ],
      );
      return;
    }
    try {
      final text = await file.readAsString();
      _config = AppConfig.fromJson(jsonDecode(text) as Map<String, dynamic>);
    } catch (_) {
      _config = AppConfig();
    }
  }

  Future<void> save() async {
    final file = await _configFile();
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(_config.toJson()),
    );
  }

  void update(AppConfig Function(AppConfig) fn) {
    _config = fn(_config);
  }
}

class HistoryStore {
  final List<PricePoint> _points = [];
  static const maxPoints = 50000;

  List<PricePoint> get points => List.unmodifiable(_points);

  Future<File> _historyFile() async {
    final store = ConfigStore();
    final dir = await store.appDir();
    return File('${dir.path}/price_history.json');
  }

  Future<void> load() async {
    final file = await _historyFile();
    if (!await file.exists()) return;
    try {
      final list = jsonDecode(await file.readAsString()) as List<dynamic>;
      _points
        ..clear()
        ..addAll(list.map((e) => PricePoint.fromJson(e as Map<String, dynamic>)));
    } catch (_) {}
  }

  Future<void> save() async {
    final file = await _historyFile();
    await file.writeAsString(jsonEncode(_points.map((p) => p.toJson()).toList()));
  }

  void addPoint(double cny, double usd) {
    _points.add(PricePoint(timestamp: DateTime.now().millisecondsSinceEpoch / 1000, cny: cny, usd: usd));
    if (_points.length > maxPoints) {
      _points.removeRange(0, _points.length - maxPoints);
    }
  }

  List<PricePoint> range(String rangeKey) {
    final seconds = AppConstants.chartRangeSeconds[rangeKey] ?? 86400;
    final cutoff = DateTime.now().millisecondsSinceEpoch / 1000 - seconds;
    return _points.where((p) => p.timestamp >= cutoff).toList();
  }
}
