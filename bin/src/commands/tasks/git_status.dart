import 'dart:io';

import 'base.dart';

class GitStatusTask extends TaskCommand {
  GitStatusTask(EnDaftCommand parent, Logger logger)
      : super(parent, logger, TaskRequirements(tools: ['git']));

  static String taskName = 'git-status';

  @override
  String get name => GitStatusTask.taskName;

  @override
  String get description => 'Check the git status for a clean directory.';

  @override
  Future<bool> run() async {
    final closer = logger.printFixed("   👀 Checking git status");
    final args = ['status', '--porcelain'];
    final gitResult = Process.runSync('git', args, workingDirectory: rootDir);
    final exitCode = gitResult.exitCode;
    final stdout = gitResult.stdout.toString();
    final result = exitCode == 0 && stdout.isEmpty;

    return closer(
      result,
      !result ? 'Not a git directory, or not a clean working tree.' : '',
    );
  }
}
