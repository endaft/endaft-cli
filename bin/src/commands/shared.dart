import 'tasks/all.dart';

class SharedCommand extends EnDaftCommand {
  @override
  final name = "shared";

  @override
  final description = "Builds the shared library for the lambdas and app.";

  @override
  String get category => 'Granular';

  final String pti = '        - ';

  SharedCommand(Logger logger) : super(logger: logger, tools: ['dart']) {
    argParser
      ..addFlag(
        'test',
        abbr: 't',
        negatable: false,
        defaultsTo: false,
        help: "Just run the tests in shared",
      )
      ..addFlag(
        'no-cache',
        negatable: false,
        defaultsTo: false,
        help: "Clear the dart cache",
      );
  }

  bool get testOnly => argResults!['test'];

  bool get noCache => argResults!['no-cache'];

  @override
  List<TaskCommand> revealTasks() => [
        CleanDirTask(this, logger),
        PubGetTask(this, logger),
        BuildRunnerCleanTask(this, logger),
        BuildRunnerBuildTask(this, logger),
        DartTestTask(this, logger)
      ];

  @override
  Future<bool> run() async {
    final closure = logger.fixed("Shared");
    final sharedDir = Utils.pathFromRoot(KnownPaths.shared, rootDir);
    final testSequence = [DartTestTask(this, childLogger())];
    final fullSequence = [
      CleanDirTask(this, childLogger()),
      PubGetTask(this, childLogger()),
      ...(noCache
          ? [
              BuildRunnerCleanTask(this, childLogger()),
            ]
          : <TaskCommand>[]),
      BuildRunnerBuildTask(this, childLogger()),
      ...testSequence
    ];

    useSequence(testOnly ? testSequence : fullSequence);

    final result = await runSequence({
      PubGetTask.taskName: {'target': sharedDir},
      CleanDirTask.taskName: {'target': sharedDir},
      DartTestTask.taskName: {'target': sharedDir},
      BuildRunnerCleanTask.taskName: {'target': sharedDir},
      BuildRunnerBuildTask.taskName: {'target': sharedDir},
    });

    return logger.close(closure(result))!;
  }
}
