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

  final inRs = '   ';

  @override
  Future<bool> run() async {
    final dirPath = targetDir;
    final ind = args['indent'] ?? inRs;
    final baseName = path.basename(dirPath);
    final distPath = path.join(dirPath, '.dist');
    final outputName = Utils.getIaCValue(dirPath, 'handler');
    final relOutPath = '.dist/$outputName';
    logger.printFixed('💪 Compiling $baseName → $outputName', ind);

    if (!Directory(distPath).existsSync()) Directory(distPath).createSync();
    final dartArgs = ['compile', 'exe', 'lib/main.dart', '-o', relOutPath];
    final pRes = Process.runSync('dart', dartArgs, workingDirectory: dirPath);

    if (!Platform.isWindows && File(relOutPath).existsSync()) {
      final chmodRes = Process.runSync('chmod', ['+x', relOutPath]);
      if (chmodRes.exitCode != 0) {
        logger.printFixed('Failed to make $outputName executable', ind);
      }
    }

    return Utils.handleProcessResult(pRes, logger, '          ', (code) {
      final outputFile = File(relOutPath);
      final success = code == 0 && outputFile.existsSync();
      if (success) Utils.chmod('+x', relOutPath);
    });
  }
}
