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
    final baseName = path.basename(dirPath);
    final closure = logger.memo('👇 Dependencies for ${baseName.green()}');

    final dartArgs = ['pub', 'get'];
    final result = await Process.start(
      'dart',
      dartArgs,
      workingDirectory: dirPath,
    ).then((p) {
      p.stdout.pipe(logger.pipeOut());
      p.stderr.pipe(logger.pipeErr());
      return p;
    });
    final exitCode = await result.exitCode;

    return logger.close(closure(exitCode == 0))!;
  }
}
