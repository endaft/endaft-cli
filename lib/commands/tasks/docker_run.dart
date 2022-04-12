import 'dart:io';

import 'package:path/path.dart' as path;

import 'base.dart';

class DockerRunTask extends TaskCommand {
  DockerRunTask(EnDaftCommand parent, Logger logger)
      : super(
            parent,
            logger,
            TaskRequirements(files: [
              AssetRequirement(Assets.dockerAmznL2),
              AssetRequirement(Assets.dockerRunScript)
            ]));

  static String taskName = 'docker-run';

  @override
  String get name => DockerRunTask.taskName;

  @override
  String get description => 'Runs a build inside a docker container.';

  final inRs = '   ';

  @override
  Future<bool> run() async {
    final rootDir = Directory.current.path;
    final imageName = "${path.basename(rootDir)}-builder";

    bool hasImage = Utils.dockerImageExists(imageName);
    logger.printFixed("🐳 Running in $imageName")(hasImage);

    final args = [
      'run',
      '--rm',
      '--name',
      imageName.toLowerCase(),
      '-v',
      '$rootDir:/home/code',
      '-v',
      '$userDir:/home/user',
      '-e',
      'CI=false',
      '-it',
      imageName.toLowerCase()
    ];
    final process = await Process.start('docker', args,
        workingDirectory: rootDir, mode: ProcessStartMode.inheritStdio);
    final result = await process.exitCode == 0;

    return result;
  }
}
