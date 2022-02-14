import 'dart:io';

import 'package:path/path.dart' as path;

import 'base.dart';

class BuildRunnerCleanTask extends TaskCommand {
  BuildRunnerCleanTask(EnDaftCommand parent, Logger logger)
      : super(parent, logger, TaskRequirements());

  static String taskName = 'build-runner-clean';

  @override
  String get name => BuildRunnerCleanTask.taskName;

  @override
  String get description =>
      'Runs `dart run build_runner clean` in the specified `target` folder';

  @override
  Future<bool> run() async {
    final dirPath = targetDir;
    final baseName = path.basename(dirPath);
    final closure = logger.memo('🏃 Runner clean ${baseName.green()}');
    final dartArgs = ['run', 'build_runner', 'clean'];
    final result = Process.runSync('dart', dartArgs, workingDirectory: rootDir);

    return logger.close(Utils.handleProcessResult(result, closure))!;
  }
}
