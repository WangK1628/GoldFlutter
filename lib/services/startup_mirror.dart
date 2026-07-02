import 'dart:io';

/// 中文/非 ASCII 安装路径下，镜像到 LOCALAPPDATA 纯英文路径再启动。
/// 主镜像逻辑在 C++ path_mirror.cpp（Flutter 初始化前执行）；此处为兜底。
class StartupMirror {
  static const mirroredFlag = '--mirrored-runtime';

  static bool _hasNonAscii(String value) => value.runes.any((r) => r > 127);

  static String _dirname(String filePath) {
    final sep = Platform.pathSeparator;
    final i = filePath.lastIndexOf(sep);
    if (i <= 0) return filePath;
    return filePath.substring(0, i);
  }

  static String _join(String a, String b) => '$a${Platform.pathSeparator}$b';

  static String _basename(String filePath) {
    final sep = Platform.pathSeparator;
    final i = filePath.lastIndexOf(sep);
    if (i < 0) return filePath;
    return filePath.substring(i + 1);
  }

  static Directory? get _mirrorRoot {
    final appData = Platform.environment['LOCALAPPDATA'];
    if (appData == null || appData.isEmpty) return null;
    return Directory(_join(_join(appData, 'GoldMonitor'), 'runtime'));
  }

  static bool get runningFromMirror {
    if (Platform.executableArguments.contains(mirroredFlag)) return true;
    final root = _mirrorRoot;
    if (root == null) return false;
    final exe = Platform.resolvedExecutable.replaceAll('/', Platform.pathSeparator);
    final base = root.path.replaceAll('/', Platform.pathSeparator);
    return exe.startsWith(base);
  }

  static bool get needsMirror {
    if (!Platform.isWindows) return false;
    if (runningFromMirror) return false;
    final exe = Platform.resolvedExecutable;
    return _hasNonAscii(exe) || _hasNonAscii(_dirname(exe));
  }

  static File? get _logFile {
    final root = _mirrorRoot;
    if (root == null) return null;
    return File(_join(root.path, 'mirror.log'));
  }

  static Future<void> _log(String message) async {
    try {
      final file = _logFile;
      if (file == null) return;
      final stamp = DateTime.now().toIso8601String();
      await file.writeAsString('[$stamp] $message\n', mode: FileMode.append);
    } catch (_) {}
  }

  static Future<void> ensureAsciiRuntime() async {
    if (!needsMirror) return;

    final srcDir = Directory(_dirname(Platform.resolvedExecutable));
    final dstDir = _mirrorRoot;
    if (dstDir == null) {
      await _log('mirror root unavailable');
      throw StateError('LOCALAPPDATA unavailable');
    }

    await _log('dart mirror from ${srcDir.path}');
    await _syncDirectory(srcDir, dstDir);

    final dstExe = _join(dstDir.path, _basename(Platform.resolvedExecutable));
    if (!File(dstExe).existsSync()) {
      await _log('mirror failed: missing $dstExe');
      throw StateError('Mirror failed: $dstExe');
    }

    final args = [mirroredFlag, ...Platform.executableArguments];
    await Process.start(
      dstExe,
      args,
      workingDirectory: dstDir.path,
      mode: ProcessStartMode.detached,
    );
    await _log('dart mirror launched $dstExe');
    exit(0);
  }

  static Future<void> _syncDirectory(Directory src, Directory dst) async {
    if (!await dst.exists()) {
      await dst.create(recursive: true);
    }

    await for (final entity in src.list(recursive: false, followLinks: false)) {
      final name = _basename(entity.path);
      final targetPath = _join(dst.path, name);
      if (entity is Directory) {
        await _syncDirectory(entity, Directory(targetPath));
      } else if (entity is File) {
        final target = File(targetPath);
        final srcModified = await entity.lastModified();
        if (!await target.exists() ||
            srcModified.isAfter(await target.lastModified())) {
          await entity.copy(target.path);
        }
      }
    }
  }
}
