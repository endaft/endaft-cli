import 'dart:io';

import 'package:path/path.dart' as path;

import 'tasks/all.dart';

class DockerCommand extends EnDaftCommand {
  @override
  final name = "docker";

  @override
  final description = "Runs a build in a EnDaft docker image,"
      "building the image first if needed.";

  @override
  String get category => 'Granular';

  DockerCommand(Logger logger)
      : super(logger: logger, tools: Utils.isInDocker ? [] : ['docker']) {
    var workDir = Directory.current.path;
    var imageName = "${path.basename(workDir)}-builder";

    argParser
      ..addOption(
        'name',
        abbr: 'n',
        help: "The name of the docker builder image. Defaults to your workspace"
            "root directory name ($imageName).",
      )
      ..addFlag(
        'build-only',
        abbr: 'b',
        defaultsTo: false,
        help: "Only build the docker image, don't automatically run it.",
      )
      ..addFlag(
        'force',
        abbr: 'f',
        defaultsTo: false,
        help: "Forces an image build even if one already exists.",
      );
  }

  @override
  List<TaskCommand> revealTasks() => [DockerRunTask(this, logger)];

  @override
  Future<bool> run() async {
    final args = argResults!;
    final String imageNameFallback = "ghcr.io/endaft/builder";
    final String imageName = args['name'] ?? imageNameFallback;

    useSequence([DockerRunTask(this, logger)]);
    bool result = await runSequence({
      DockerRunTask.taskName: {'name': imageName},
    });

    return result;
  }
}
