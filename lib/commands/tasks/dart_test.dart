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

  final inRs = '   ';

  bool _runTests(
    BlockLogger logger,
    bool useCoverage,
    String dirPath,
    String ind,
  ) {
    final usesCover = useCoverage && Utils.isCommand('collect_coverage');
    logger.printFixed('🏃 Running tests', ind);

    final List<String> dartArgs = [
      'run',
      'test',
      '--chain-stack-traces',
      ...(usesCover ? ['--coverage=coverage'] : []),
    ];
    final tRes = Process.runSync('dart', dartArgs, workingDirectory: dirPath);

    return Utils.handleProcessResult(tRes, logger, ind);
  }

  bool _formatLcov(
    BlockLogger logger,
    bool useCoverage,
    String baseName,
    String ind,
    String dirPath,
  ) {
    final usesCover = useCoverage && Utils.isCommand('format_coverage');

    // Early bail-out if there's nothing we can do here
    if (!usesCover) return true;

    logger.printFixed('🦾 Formatting coverage', ind);
    final List<String> formatArgs = [
      '--base-directory=${path.normalize(dirPath)}',
      '--report-on=lib',
      '--lcov',
      '-o',
      'coverage/lcov.info',
      '-i',
      'coverage',
    ];
    final fRes = Process.runSync(
      'format_coverage',
      formatArgs,
      workingDirectory: dirPath,
    );
    return Utils.handleProcessResult(
      fRes,
      logger,
      inRs + inRs,
    );
  }

  bool _formatHtml(
    BlockLogger logger,
    bool useCoverage,
    String baseName,
    String ind,
    String dirPath,
  ) {
    // Early bail-out if there's nothing we can do here
    final hasGenHtml = Utils.isCommand('genhtml');
    if (hasGenHtml) {
      logger.printFixed('📝 Marking up coverage', ind);
      final List<String> markupArgs = [
        '-o',
        './coverage/report',
        './coverage/lcov.info',
      ];
      final gRes =
          Process.runSync('genhtml', markupArgs, workingDirectory: dirPath);
      return Utils.handleProcessResult(
        gRes,
        logger,
        inRs + inRs,
        (code) {
          logger.useMemo("${_makeBadge(dirPath).trim()} → "
              "./$baseName/coverage/report/index.html");
        },
        './$baseName/coverage/report/index.html',
      );
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

  @override
  Future<bool> run() async {
    final dirPath = targetDir;
    final ind = args['indent'] ?? inRs;
    final baseName = path.basename(dirPath);
    final useCoverage = args['coverage'] ?? true;
    final blkLogger = logger.collapsibleBlock('🧪 Testing $baseName', ind);

    final hasTestDir = Directory(path.join(targetDir, 'test')).existsSync();
    if (!hasTestDir) {
      blkLogger.printSkipped(blkLogger.useMemo('missing test directory'));
      return true;
    }

    final usesTests =
        (Utils.getPubSpecValue(targetDir, 'dev_dependencies.test') ??
                Utils.getPubSpecValue(targetDir, 'dependencies.test')) !=
            null;
    if (!usesTests) {
      blkLogger.printSkipped(blkLogger.useMemo('missing test in pubspec'));
      return true;
    }

    bool result = _runTests(blkLogger, useCoverage, dirPath, ind + ind);
    if (result) {
      result = _formatLcov(
        blkLogger,
        useCoverage,
        baseName,
        ind + ind,
        dirPath,
      );
    }
    if (result) {
      result = _formatHtml(
        blkLogger,
        useCoverage,
        baseName,
        ind + ind,
        dirPath,
      );
    }

    return blkLogger.close(result);
  }
}
