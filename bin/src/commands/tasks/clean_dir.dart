import 'dart:io';

import 'package:path/path.dart' as path;

import 'base.dart';

class CleanDirTask extends TaskCommand {
  CleanDirTask(EnDaftCommand parent, Logger logger)
      : super(parent, logger, TaskRequirements());

  static String taskName = 'clean-dir';

  @override
  String get name => CleanDirTask.taskName;

  @override
  String get description =>
      'Cleans, or purges, known outputs in the specified `target` folder';

  @override
  Future<bool> run() async {
    String? reason;
    bool result = true;
    final dirPath = targetDir;
    final baseName = path.basename(dirPath);
    final closer = logger.memo('🧼 Cleaning ${baseName.green()}');

    try {
      final targets = [
        '.dist', /* '.dart_tool', '.packages', 'pubspec.lock' */
      ];
      for (var target in targets) {
        Utils.deleteIfExists(path.join(dirPath, target));
      }
    } on FileSystemException catch (e) {
      result = false;
      reason = e.message;
    }

    return logger.close(closer(result, reason: reason))!;
  }
}
