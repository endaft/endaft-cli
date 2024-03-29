import 'package:args/args.dart';

import 'tasks/all.dart';

class BuildCommand extends EnDaftCommand {
  @override
  final name = "build";

  @override
  final description = "The primary interaction command. This runs an"
      " orchestrated build, excluding your app, and produces a .dist folder"
      " in your workspace root with the outputs for server deployment.";

  @override
  String get category => 'General';

  @override
  ArgParser get argParser => ArgParser.allowAnything(); // Pass-thru to sequence

  @override
  List<TaskCommand> revealTasks() => [];

  BuildCommand(Logger logger) : super(logger: logger, tools: []);

  @override
  Future<bool> run() async {
    final runner = super.runner!;
    final dockerSeq = [
      'check',
      'validate',
      'shared',
      'docker',
      'aggregate',
      'deps',
    ];
    final buildSeq = ['check', 'lambda'];
    final execSeq = (Utils.isInDocker ? buildSeq : dockerSeq);

    final baseArgs = (argResults?.arguments ?? []).where((a) => a != name);
    for (var step in execSeq) {
      final cmd = runner.commands[step];
      if (cmd == null) throw Exception('A sequenced command is missing! 🪲');

      final cmdArgs = baseArgs.where((argName) =>
          cmd.argParser
              .findByNameOrAlias(argName.replaceAll(RegExp('-'), '')) !=
          null);
      final args = [cmd.name, ...cmdArgs];
      final result = (await runner.run(args)) ?? false;
      if (!result) throw Exception('Step Failed: $step 😢');
    }

    return true;
  }
}
