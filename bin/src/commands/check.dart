import 'tasks/all.dart';

class CheckCommand extends EnDaftCommand {
  @override
  final name = "check";

  @override
  final description = "Checks your environment for EnDaft required tools.";

  @override
  String get category => 'General';

  CheckCommand(Logger logger) : super(logger: logger, tools: []) {
    argParser.addFlag(
      'fix',
      negatable: false,
      defaultsTo: false,
      help: "When set, creates missing folders.",
    );
  }

  bool get useFix => argResults!['fix'];

  @override
  List<TaskCommand> revealTasks() => [
        CheckToolsTask(this, logger),
        CheckFSTask(this, logger),
      ];

  @override
  Future<bool> run() async {
    final closure = logger.fixed('Checks');
    useSequence([
      CheckToolsTask(this, childLogger()),
      CheckFSTask(this, childLogger()),
    ]);

    bool result = await runSequence({
      CheckFSTask.taskName: {'fix': useFix}
    });

    if (!result) {
      logger.warn(
        'Some errors can be fixed automatically using the '
        '${'endaft check --fix'.bold()}.',
      );
    }

    return logger.close(closure(result))!;
  }
}
