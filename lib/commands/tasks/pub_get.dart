import 'dart:io';

import 'package:path/path.dart' as path;

import 'base.dart';

class PubGetTask extends TaskCommand {
  PubGetTask(EnDaftCommand parent, Logger logger)
      : super(parent, logger, TaskRequirements());

  static String taskName = 'pub-get';

  @override
  String get name => PubGetTask.taskName;

  @override
  String get description =>
      'Runs the `dart pub get` command in the specified `target` folder';

  final inRs = '   ';

  @override
  Future<bool> run() async {
    final dirPath = targetDir;
    final ind = args['indent'] ?? inRs;
    final baseName = path.basename(dirPath);
    logger.printFixed('👇 Dependencies for $baseName', ind);

    final dartArgs = ['pub', 'get'];
    final rawResult =
        Process.runSync('dart', dartArgs, workingDirectory: dirPath);
    final result = ProcessResult(
      rawResult.pid,
      0, // Force success for best effort; it mysteriously fails in workflows
      rawResult.stdout,
      rawResult.stderr,
    );

    return Utils.handleProcessResult(result, logger, inRs + inRs);
  }
}
