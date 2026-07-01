import 'dart:io';

import 'package:launch_at_startup/launch_at_startup.dart';

import '../core/constants.dart';

class AutostartService {
  static Future<void> init() async {
    if (!Platform.isWindows) return;
    launchAtStartup.setup(
      appName: AppConstants.appName,
      appPath: Platform.resolvedExecutable,
    );
  }

  static Future<bool> isEnabled() async {
    try {
      return await launchAtStartup.isEnabled();
    } catch (_) {
      return false;
    }
  }

  static Future<void> setEnabled(bool enabled) async {
    if (enabled) {
      await launchAtStartup.enable();
    } else {
      await launchAtStartup.disable();
    }
  }

  static void setAppUserModelId() {
    // Windows 任务栏分组 ID — 可选，失败时忽略
  }
}
