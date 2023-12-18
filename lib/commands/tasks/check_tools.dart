import 'base.dart';

class CheckToolsTask extends TaskCommand {
  CheckToolsTask(EnDaftCommand parent, Logger logger)
      : super(parent, logger, TaskRequirements());

  static String taskName = 'check-tools';

  @override
  String get name => CheckToolsTask.taskName;

  @override
  String get description => 'Checks for each required tool.';

  final inRs = '   ';

  @override
  Future<bool> run() async {
    final bool fix = args['fix'];
    final List<String> tools = parent.globalTools;

    List<bool> results = [];
    for (var tool in tools) {
      final closer = logger.printFixed('👀 Looking for $tool', inRs);
      final exists = Utils.isCommand(tool);
      if (!exists && fix) {
        final res = Utils.installCommand(tool);
        results.add(closer(res));
      } else {
        results.add(closer(exists));
      }
    }

    final result = results.every((r) => r);
    return result;
  }
}
