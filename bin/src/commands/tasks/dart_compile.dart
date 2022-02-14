import 'dart:io';

import 'package:path/path.dart' as path;

import 'base.dart';

class DartCompileTask extends TaskCommand {
  DartCompileTask(EnDaftCommand parent, Logger logger)
      : super(parent, logger, TaskRequirements());

  static String taskName = 'dart-compile';

  @override
  String get name => DartCompileTask.taskName;

  @override
  String get description => 'Uses `dart` to compile sources.';

  @override
  Future<bool> run() async {
    final dirPath = targetDir;
    final baseName = path.basename(dirPath);
    final distPath = path.join(dirPath, '.dist');
    final outputName = Utils.getIaCValue(dirPath, 'handler');
    final relOutPath = '.dist/$outputName';
    final closure = logger.memo(
      '💪 Compiling ${baseName.green()} → ${outputName?.green()}',
    );

    if (!Directory(distPath).existsSync()) Directory(distPath).createSync();
    final dartArgs = ['compile', 'exe', 'lib/main.dart', '-o', relOutPath];
    final pRes = Process.runSync('dart', dartArgs, workingDirectory: dirPath);

    return logger.close(Utils.handleProcessResult(pRes, closure, (code) {
      final outputFile = File(relOutPath);
      final success = code == 0 && outputFile.existsSync();
      if (success) Utils.chmod('+x', relOutPath);
    }))!;
  }
}
