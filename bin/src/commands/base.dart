import 'dart:io';
import 'package:path/path.dart' as path;

import 'package:args/command_runner.dart';

import 'tasks/base.dart';
export '../enums.dart';

typedef ArgsProvider = Map<String, dynamic>? Function(String taskName);

abstract class EnDaftCommand extends Command<bool> {
  EnDaftCommand({required this.tools, required this.logger}) {
    var workDir = Directory.current.path;
    if (!argParser.allowsAnything) {
      argParser.addOption(
        'root',
        abbr: 'r',
        defaultsTo: path.relative(workDir, from: workDir),
        help: "The root path to process. Should be your workspace root.",
      );
    }
  }

  /// Gets the normalized active root directory for the command
  String get rootDir => Utils.getFinalDir(argResults!['root']);

  /// Private storage for the sequence
  List<TaskCommand> _sequence = [];

  /// A logger instance
  final Logger logger;

  /// The external tools (commands and exes) required by the command
  final List<String> tools;

  /// Reveals all tasks potentially used by the command.
  List<TaskCommand> revealTasks();

  /// Gets a [Logger] by slicing [logger] or [from].
  Logger childLogger([Logger? from]) {
    return (from ?? logger).slice();
  }

  /// Sets the sequence of tasks run by this command
  void useSequence(List<TaskCommand> sequence) {
    _sequence = sequence;
  }

  /// All commands known to the [runner]
  List<EnDaftCommand> get allCommands =>
      (runner?.commands.values ?? []).whereType<EnDaftCommand>().toList();

  /// All [tools] from this commands [sequence]
  List<String> get allTools => [
        ...tools,
        ...revealTasks().map((e) => e.requirements.tools).expand((e) => e)
      ];

  /// All [TaskRequirements.files] from this commands [sequence]
  List<FileRequirement> get allFsPaths =>
      [...revealTasks().map((e) => e.requirements.files).expand((e) => e)];

  /// A sorted, distinct list of [allTools] from [allCommands]
  List<String> get globalTools =>
      allCommands.map((e) => e.allTools).expand((e) => e).toSet().toList()
        ..sort();

  /// A sorted, distinct list of [allFsPaths] from [allCommands]
  List<FileRequirement> get globalFsPaths =>
      allCommands.map((e) => e.allFsPaths).expand((e) => e).toSet().toList()
        ..sort();

  /// Executes this commands [sequence] with the mapped [args] or empty args
  Future<bool> runSequence(
      [Map<String, Map<String, dynamic>> args = const {}]) async {
    bool result = true;
    final _def = <String, dynamic>{};
    for (var task in _sequence) {
      if (!result) {
        break;
      } else {
        final ta = (args.containsKey(task.name) ? args[task.name] : _def)!;
        result = await task.runWith(ta) ?? false;
      }
    }
    return result;
  }

  /// Executes this commands [sequence] invoking the provider for each task's args.
  Future<bool> runSequenceSame(ArgsProvider provider) async {
    bool result = true;
    final _def = <String, dynamic>{};
    for (var task in _sequence) {
      if (!result) {
        break;
      } else {
        final ta = (provider(task.name) ?? _def);
        result = await task.runWith(ta) ?? false;
      }
    }
    return result;
  }
}
