import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/fortune_service.dart';
import 'local_store.dart';

/// 每日一签持久化 — 按自然日保存。
class FortuneStore {
  FortuneDailyRecord? _today;

  FortuneDailyRecord? get today => _today;

  String _todayKey() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }

  Future<File> _file() async {
    final dir = await ConfigStore().appDir();
    return File('${dir.path}/fortune_daily.json');
  }

  Future<void> load() async {
    final file = await _file();
    if (!await file.exists()) {
      _today = null;
      return;
    }
    try {
      final j = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      final rec = FortuneDailyRecord.fromJson(j);
      _today = rec.date == _todayKey() ? rec : null;
    } catch (_) {
      _today = null;
    }
  }

  Future<void> save(FortuneDailyRecord record) async {
    _today = record;
    final file = await _file();
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(record.toJson()));
  }
}

class FortuneDailyRecord {
  FortuneDailyRecord({required this.date, required this.wish, required this.stick});

  final String date;
  final String wish;
  final FortuneStick stick;

  Map<String, dynamic> toJson() => {
        'date': date,
        'wish': wish,
        'stick': stick.toJson(),
      };

  factory FortuneDailyRecord.fromJson(Map<String, dynamic> j) => FortuneDailyRecord(
        date: j['date'] as String? ?? '',
        wish: j['wish'] as String? ?? '',
        stick: FortuneStick.fromJson(j['stick'] as Map<String, dynamic>? ?? {}),
      );
}

final fortuneStoreProvider = Provider<FortuneStore>((ref) => FortuneStore());
