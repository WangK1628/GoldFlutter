import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ui/widgets/notification_toast.dart';

/// 统一通知：桌面气泡 + 系统通知栏。
class NotificationService {
  NotificationService(this.ref);

  final Ref ref;

  void notify({
    required String title,
    required String body,
    bool bubble = true,
    bool system = true,
    NotificationKind kind = NotificationKind.alert,
    Duration duration = const Duration(seconds: 4),
  }) {
    if (bubble) {
      ref.read(notificationQueueProvider.notifier).push(
            AppNotification(
              title: title,
              body: body,
              kind: kind,
              duration: duration,
            ),
          );
    }
    if (system && Platform.isWindows) {
      _showWindowsToast(title, body);
    }
  }

  Future<void> _showWindowsToast(String title, String body) async {
    try {
      final t = _escapeXml(title);
      final b = _escapeXml(body);
      final xml =
          '<toast><visual><binding template="ToastText02"><text id="1">$t</text><text id="2">$b</text></binding></visual></toast>';
      await Process.run(
        'powershell',
        [
          '-NoProfile',
          '-NonInteractive',
          '-Command',
          r'''
[Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null
[Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime] | Out-Null
$xml = New-Object Windows.Data.Xml.Dom.XmlDocument
$xml.LoadXml(@"
''' +
              xml +
              r'''
"@)
$toast = [Windows.UI.Notifications.ToastNotification]::new($xml)
[Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier("Gold Monitor").Show($toast)
''',
        ],
        runInShell: false,
      );
    } catch (_) {}
  }

  String _escapeXml(String s) =>
      s.replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;').replaceAll('"', '&quot;');
}

final notificationServiceProvider = Provider<NotificationService>((ref) => NotificationService(ref));
