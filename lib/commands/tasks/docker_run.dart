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
    final bool use2023 = args['use2023'];
    final String imageTag = use2023 ? '-2023' : '';
    final imageName = "ghcr.io/endaft/builder:latest$imageTag";

    String tempDir = Utils.getTempPath();
    String envCi = String.fromEnvironment("CI", defaultValue: 'false');
    bool hasImage = Utils.dockerImageExists(imageName);
    logger.printFixed("🐳 Running in $imageName")(hasImage);

    final dockerArgs = [
      'run',
      '--rm',
      '--name',
      'endaft-builder$imageTag',
      '-v',
      '$rootDir:/home/code',
      '-e',
      'CI=$envCi',
      '-i',
      imageName.toLowerCase()
    ];
    final process = await Process.start('docker', dockerArgs,
        workingDirectory: rootDir, mode: ProcessStartMode.inheritStdio);
    final result = await process.exitCode == 0;

    if (!result) {
      logger.printFixed(
          "🐳 Failed to run docker build using:\n\tdocker ${dockerArgs.join(" ")}\n");
    }

    try {
      Directory(tempDir).deleteSync(recursive: true);
    } catch (e) {
      logger.printFixed("🐳 Failed to delete temp dir: $tempDir");
    }

    return result;
  }
}
