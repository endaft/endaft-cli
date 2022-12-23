import 'dart:io';

import 'package:collection/collection.dart';
import 'package:path/path.dart' as path;

import 'tasks/all.dart';

class DepsCommand extends EnDaftCommand {
  @override
  final name = "deps";

  @override
  final description = "Install appropriate dependencies for the projects on "
      "the current machine.";

  @override
  String get category => 'Granular';

  @override
  List<TaskCommand> revealTasks() => [];

  DepsCommand(Logger logger) : super(logger: logger, tools: ['dart']);

  @override
  Future<bool> run() async {
    bool result = true;
    final closer = logger.header("Dependencies");

    logger.printFixed('   🔎 Finding lambdas');
    final String lambdasPath = path.join(rootDir, 'lambdas');
    final lambdaRoots = Directory(lambdasPath)
        .listSync(recursive: false, followLinks: false)
        .whereType<Directory>()
        .map((e) => e.path)
        .toList(growable: false)
        .sorted();
    logger.printDone('found ${lambdaRoots.length}');

    final ind = '   ';
    final subInd = ind + ind;
    for (var lambdaDir in lambdaRoots) {
      var lambdaName = path.basename(lambdaDir);
      final blockLogger = logger.collapsibleBlock(
        "👇  Resetting $lambdaName",
        ind,
      );

      useSequence([PubGetTask(this, blockLogger)]);
      result = await runSequence({
        PubGetTask.taskName: {'target': lambdaDir, 'indent': subInd},
      });

      result = blockLogger.close(result);
    }

    return closer(result);
  }
}
