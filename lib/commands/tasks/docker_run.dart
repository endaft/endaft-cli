import 'dart:io';

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
    final imageName = "ghcr.io/endaft/builder";

    String tempDir = Utils.getTempPath();
    String envCi = String.fromEnvironment("CI", defaultValue: 'false');
    bool hasImage = Utils.dockerImageExists(imageName);
    logger.printFixed("🐳 Running in $imageName")(hasImage);

    final args = [
      'run',
      '--rm',
      '--name',
      'endaft-builder',
      '-v',
      '$rootDir:/home/code',
      '-v',
      '$tempDir:/var/dart_pub_cache',
      '-e',
      'CI=$envCi',
      '-i',
      imageName.toLowerCase()
    ];
    final process = await Process.start('docker', args,
        workingDirectory: rootDir, mode: ProcessStartMode.inheritStdio);
    final result = await process.exitCode == 0;

    try {
      Directory(tempDir).deleteSync(recursive: true);
    } catch (e) {
      logger.printFixed("🐳 Failed to delete temp dir: $tempDir");
    }

    return result;
  }
}
