import 'dart:io';

import 'package:win32/win32.dart';

import '../models/app_config.dart';

typedef AlertPopup = void Function(String title, String message);
typedef AlertNotify = void Function(String message);

class AlertService {
  void check(
    double price,
    AppConfig config, {
    required void Function(AppConfig) onSave,
    AlertPopup? onPopup,
    AlertNotify? onNotify,
  }) {
    if (price <= 0) return;
    var changed = false;
    for (final alert in config.alerts) {
      final should = alert.direction == 'above'
          ? price >= alert.price
          : price <= alert.price;
      if (should && !alert.triggered) {
        alert.triggered = true;
        changed = true;
        _fire(alert, price, onPopup: onPopup, onNotify: onNotify);
      } else if (!should && alert.triggered) {
        alert.triggered = false;
        changed = true;
      }
    }
    if (changed) onSave(config);
  }

  void _fire(
    AlertRule alert,
    double price, {
    AlertPopup? onPopup,
    AlertNotify? onNotify,
  }) {
    final dir = alert.direction == 'above' ? '突破' : '跌破';
    final message = '${alert.note}\n现价 ${price.toStringAsFixed(2)} 元/克，已$dir ${alert.price.toStringAsFixed(2)}';
    if (alert.sound && Platform.isWindows) {
      Beep(900, 400);
      Beep(1200, 400);
    }
    if (alert.notification) onNotify?.call(message);
    if (alert.popup) onPopup?.call('价格预警', message);
  }

  void resetAll(AppConfig config, void Function(AppConfig) onSave) {
    for (final a in config.alerts) {
      a.triggered = false;
    }
    onSave(config);
  }
}
