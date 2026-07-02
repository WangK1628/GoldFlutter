import 'dart:io';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import 'package:gold_monitor/services/single_instance.dart';
import 'package:gold_monitor/services/startup_mirror.dart';
import 'package:gold_monitor/ui/screens/shell_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isWindows) {
    try {
      await StartupMirror.ensureAsciiRuntime();
    } catch (e) {
      // C++ 层应已处理；Dart 兜底失败时写日志，避免静默死在中文路径。
      try {
        final logDir = Platform.environment['LOCALAPPDATA'];
        if (logDir != null) {
          final log = File(
            '$logDir${Platform.pathSeparator}GoldMonitor${Platform.pathSeparator}runtime${Platform.pathSeparator}mirror.log',
          );
          await log.writeAsString(
            '[${DateTime.now().toIso8601String()}] dart mirror error: $e\n',
            mode: FileMode.append,
          );
        }
      } catch (_) {}
    }
    if (!SingleInstance.acquire()) {
      exit(0);
    }
  }
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    await windowManager.ensureInitialized();
    const options = WindowOptions(
      size: Size(360, 420),
      minimumSize: Size(360, 260),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.hidden,
      windowButtonVisibility: false,
    );
    windowManager.waitUntilReadyToShow(options, () async {
      await windowManager.setAsFrameless();
      await windowManager.setBackgroundColor(Colors.transparent);
      await windowManager.setHasShadow(false);
      await windowManager.show();
      await windowManager.focus();
    });
  }

  runApp(const ProviderScope(child: GoldMonitorApp()));
}
