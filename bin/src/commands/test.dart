import 'dart:collection';

import 'tasks/all.dart';

class TestCommand extends EnDaftCommand {
  @override
  final name = "test";

  @override
  final description =
      "Runs dart run test with coverage (if available). Can produce GCOV, LCOV or Cobertura.";

  @override
  String get category => 'General';

  TestCommand(Logger logger) : super(logger: logger, tools: []) {
    argParser
      ..addOption('style',
          abbr: 's',
          allowed: ['gcov', 'lcov'],
          defaultsTo: 'gcov',
          help: "If coverage is used, determines the output type.")
      ..addFlag(
        'coverage',
        abbr: 'c',
        defaultsTo: true,
        help: "Indicates if code coverage should be calculated or not.",
      );
  }

  String get style => argResults!['style'];

  bool get coverage => argResults!['coverage'];

  @override
  List<TaskCommand> revealTasks() => [DartTestTask(this, logger)];

  @override
  Future<bool> run() async {
    final bLogger = logger.collapsibleBlock("🤖 Processing ${'Test'.green()}");
    final targets = Queue<String>.from(
        await Utils.findFiles(matcher: RegExps.filePubSpecYaml).toList().then(
            (files) => files
                .where((e) =>
                    e.parent.path.endsWith('shared') ||
                    e.parent.parent.path.endsWith('lambdas'))
                .map((e) => e.parent.path)
                .toList()));
    useSequence(targets.map((e) => DartTestTask(this, bLogger)).toList());
    final result = await runSequenceSame((taskName) {
      return {
        'style': style,
        'target': targets.removeLast(),
        'coverage': coverage,
        'indent': '   '
      };
    });

    bLogger.footer('Test');
    return result;
  }
}
