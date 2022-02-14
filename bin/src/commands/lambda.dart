import 'dart:io';

import 'package:path/path.dart' as path;

import 'tasks/all.dart';

class LambdaCommand extends EnDaftCommand {
  @override
  final name = "lambda";

  @override
  final description = "Builds and packages lambdas for distribution.";

  @override
  String get category => 'Granular';

  LambdaCommand(Logger logger) : super(logger: logger, tools: ['dart']) {
    argParser.addFlag(
      'test',
      abbr: 't',
      negatable: false,
      defaultsTo: false,
      help: "Just run the tests in lambdas",
    );
  }

  bool get testOnly => argResults!['test'];

  @override
  List<TaskCommand> revealTasks() => [
        CleanDirTask(this, logger),
        PubGetTask(this, logger),
        DartTestTask(this, logger),
        DartCompileTask(this, logger),
        ZipArchiveTask(this, logger)
      ];

  Future<bool> handleLambda(String lambdaDir, Logger levelLogger) async {
    final lambdaName = path.basename(lambdaDir);
    final closure = levelLogger.fixed("ƛ  Handling ${lambdaName.green()}");
    final outputName = Utils.getIaCValue(lambdaDir, 'handler');
    final zipInAssets = path.join(lambdaDir, 'assets');
    final zipInLambda = path.join(lambdaDir, '.dist', outputName);
    final zipOutput = path.join(lambdaDir, '.dist', 'lambda_$lambdaName.zip');
    final lambdaInputs = [zipInLambda];

    if (Directory(zipInAssets).existsSync()) {
      lambdaInputs.add(zipInAssets);
    }

    final testSequence = [DartTestTask(this, childLogger(levelLogger))];
    final fullSequence = [
      CleanDirTask(this, childLogger(levelLogger)),
      PubGetTask(this, childLogger(levelLogger)),
      ...testSequence,
      DartCompileTask(this, childLogger(levelLogger)),
      ZipArchiveTask(this, childLogger(levelLogger))
    ];

    useSequence(testOnly ? testSequence : fullSequence);

    final result = await runSequence({
      CleanDirTask.taskName: {'target': lambdaDir},
      PubGetTask.taskName: {'target': lambdaDir},
      DartTestTask.taskName: {'target': lambdaDir},
      DartCompileTask.taskName: {'target': lambdaDir},
      ZipArchiveTask.taskName: {
        'input': lambdaInputs.join(','),
        'output': zipOutput
      },
    });

    return closure(result);
  }

  @override
  Future<bool> run() async {
    final closure = logger.fixed("Lambdas");
    final levelLogger = childLogger();

    final findClosure = levelLogger.fixed('🔎 Finding lambdas');
    final lambdasPath = path.join(rootDir, 'lambdas');
    final lambdaRoots = Directory(lambdasPath)
        .listSync(recursive: false, followLinks: false)
        .whereType<Directory>()
        .map((e) => e.path)
        .toList(growable: false);
    findClosure(true, 'found ${lambdaRoots.length}');

    final lambdas = lambdaRoots.map((dir) => handleLambda(dir, levelLogger));
    final results = await Future.wait(lambdas);
    final result = results.any((r) => !r);
    return logger.close(closure(result))!;
  }
}
