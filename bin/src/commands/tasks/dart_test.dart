import 'dart:io';

import 'package:path/path.dart' as path;

import 'base.dart';

class DartTestTask extends TaskCommand {
  DartTestTask(EnDaftCommand parent, Logger logger)
      : super(
            parent,
            logger,
            TaskRequirements(
              tools: [
                'dart',
                'collect_coverage',
                'format_coverage',
                'cobertura',
                'genhtml'
              ],
            ));

  static String taskName = 'dart-test';

  @override
  String get name => DartTestTask.taskName;

  @override
  String get description => 'Uses `dart run` to run tests.';

  Future<bool> _runTests(bool useCoverage, String dirPath) async {
    final usesCover = useCoverage && Utils.isCommand('collect_coverage');
    final closure = logger.memo('🏃 Running tests');

    final List<String> dartArgs = [
      'run',
      'test',
      '--chain-stack-traces',
      ...(usesCover ? ['--coverage=coverage'] : []),
    ];

    final childLogger = logger.slice();
    final result = await Process.start(
      'dart',
      dartArgs,
      workingDirectory: dirPath,
    ).then((p) {
      p.stdout.pipe(childLogger.pipeOut());
      p.stderr.pipe(childLogger.pipeErr());
      return p;
    });
    final exitCode = await result.exitCode;

    return closure(exitCode == 0);
  }

  Future<bool> _formatLcov(
    bool useCoverage,
    String baseName,
    String dirPath,
  ) async {
    final usesCover = useCoverage && Utils.isCommand('format_coverage');

    // Early bail-out if there's nothing we can do here
    if (!usesCover) return true;

    final closure = logger.memo('🦾 Formatting coverage');
    final List<String> formatArgs = [
      '--packages=.packages',
      '--base-directory=${path.normalize(dirPath)}',
      '--report-on=lib',
      '--lcov',
      '-o',
      'coverage/lcov.info',
      '-i',
      'coverage',
    ];

    final childLogger = logger.slice();
    final result = await Process.start(
      'format_coverage',
      formatArgs,
      workingDirectory: dirPath,
    ).then((p) {
      p.stdout.pipe(childLogger.pipeOut());
      p.stderr.pipe(childLogger.pipeErr());
      return p;
    });
    final exitCode = await result.exitCode;

    return closure(exitCode == 0);
  }

  Future<bool> _formatHtml(
    bool useCoverage,
    String baseName,
    String dirPath,
  ) async {
    // Early bail-out if there's nothing we can do here
    final hasGenHtml = Utils.isCommand('genhtml');
    if (hasGenHtml) {
      final closure = logger.memo('📝 Marking up coverage');
      final List<String> markupArgs = [
        '-o',
        './coverage/report',
        './coverage/lcov.info',
      ];

      final childLogger = logger.slice();
      final result = await Process.start(
        'genhtml',
        markupArgs,
        workingDirectory: dirPath,
      ).then((p) {
        p.stdout.pipe(childLogger.pipeOut());
        p.stderr.pipe(childLogger.pipeErr());
        return p;
      });
      final exitCode = await result.exitCode;

      return closure(exitCode == 0);
    }
    return true;
  }

  String _makeBadge(String dirPath) {
    final List<String> badgeArgs = [
      'pub',
      'global',
      'run',
      'cobertura',
      'show',
      '-b',
      '-i',
      './coverage/lcov.info',
    ];
    final bRes = Process.runSync('dart', badgeArgs, workingDirectory: dirPath);
    return bRes.stdout;
  }

  bool get useCoverage => args['coverage'] ?? true;

  @override
  Future<bool> run() async {
    final dirPath = targetDir;
    final baseName = path.basename(dirPath);
    final closure = logger.memo(
      '🧪 Testing ${baseName.green()}',
      collapse: false,
    );

    final hasTestDir = Directory(path.join(targetDir, 'test')).existsSync();
    if (!hasTestDir) {
      return closure(
        true,
        icon: LogIcon.skipped,
        reason: 'missing test directory',
      );
    }

    final usesTests =
        (Utils.getPubSpecValue(targetDir, 'dev_dependencies.test') ??
                Utils.getPubSpecValue(targetDir, 'dependencies.test')) !=
            null;
    if (!usesTests) {
      return closure(
        true,
        icon: LogIcon.skipped,
        reason: 'missing "test: n.n.n" in pubspec',
      );
    }

    bool result = await _runTests(useCoverage, dirPath);
    if (result) result = await _formatLcov(useCoverage, baseName, dirPath);
    if (result) result = await _formatHtml(useCoverage, baseName, dirPath);

    return logger.close(closure(
      result,
      reason: '${_makeBadge(dirPath).trim()} → '
          './$baseName/coverage/report/index.html',
    ))!;
  }
}
