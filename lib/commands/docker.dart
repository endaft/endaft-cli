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
    argParser.addFlag(
      'useClassic',
      abbr: 'c',
      help: "If the Amazon Linux 2023-based image should be used or not.",
    );
  }

  @override
  List<TaskCommand> revealTasks() => [DockerRunTask(this, logger)];

  @override
  Future<bool> run() async {
    final args = argResults!;
    final bool useClassic = args.wasParsed('useClassic');

    useSequence([DockerRunTask(this, logger)]);
    bool result = await runSequence({
      DockerRunTask.taskName: {'use2023': !useClassic},
    });

    return result;
  }
}
