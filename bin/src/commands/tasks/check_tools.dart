import 'base.dart';

class CheckToolsTask extends TaskCommand {
  CheckToolsTask(EnDaftCommand parent, Logger logger)
      : super(parent, logger, TaskRequirements());

  @override
  String get name => 'check-tools';

  @override
  String get description => 'Checks for each required tool.';

  @override
  Future<bool> run() async {
    final List<String> tools = parent.globalTools;

    List<bool> results = [];
    for (var tool in tools) {
      final closer = logger.memo('👀 Looking for ${tool.green()}');
      final result = Utils.isCommand(tool);
      results.add(closer(result));
    }

    final result = results.every((r) => r);
    return logger.close(result)!;
  }
}
