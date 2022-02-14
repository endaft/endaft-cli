import 'dart:io';

import 'package:path/path.dart' as path;

import 'base.dart';

class DockerBuildTask extends TaskCommand {
  DockerBuildTask(EnDaftCommand parent, Logger logger)
      : super(
            parent,
            logger,
            TaskRequirements(files: [
              AssetRequirement(Assets.dockerAmznL2),
              AssetRequirement(Assets.dockerRunScript)
            ]));

  static String taskName = 'docker-build';

  @override
  String get name => DockerBuildTask.taskName;

  @override
  String get description => 'Builds the required docker image.';

  String get imageName => args['name'];

  @override
  Future<bool> run() async {
    final rootDir = Directory.current.path;
    final endaftDir = Utils.pathFromRoot(KnownPaths.endaft);
    final dockerDir = path.relative(endaftDir);

    final closure = logger.memo("🧱 Building ${imageName.green()} image");
    final dockerArgs = [
      'build',
      '-q',
      '--rm',
      '--build-arg',
      'SOURCE_PATH=$rootDir',
      '--build-arg',
      'USER_HOME=$userDir',
      '-t',
      imageName,
      '-f',
      'Dockerfile.al2',
      '.'
    ];

    final result = await Process.start(
      'docker',
      dockerArgs,
      workingDirectory: dockerDir,
    ).then((p) {
      p.stdout.pipe(logger.pipeOut());
      p.stderr.pipe(logger.pipeErr());
      return p;
    });

    final exitCode = await result.exitCode;
    return logger.close(closure(exitCode == 0))!;
  }
}
