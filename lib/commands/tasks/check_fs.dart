import 'dart:io';

import 'package:path/path.dart' as path;

import 'base.dart';

class CheckFSTask extends TaskCommand {
  CheckFSTask(EnDaftCommand parent, Logger logger)
      : super(parent, logger, TaskRequirements());

  static String taskName = 'check-fs';

  @override
  String get name => CheckFSTask.taskName;

  @override
  String get description => 'Checks for folders and files.';

  final inRs = '   ';

  @override
  Future<bool> run() async {
    final bool fix = args['fix'];
    final List<FileRequirement> fsPaths = parent.globalFsPaths;

    List<bool> results = [];
    for (var fsp in fsPaths) {
      final name = path.basename(fsp.path);
      final closer = logger.printFixed('📂 Checking for ${name.green()}', inRs);
      final file = File(fsp.path);
      bool exists = file.existsSync();
      String reason = '';
      if (!exists && fix && fsp.canCreate) {
        exists = fsp.creator!(file: file);
      } else {
        reason = 'can fix';
      }
      results.add(closer(exists, reason));
    }

    final result = results.every((r) => r);
    return result;
  }
}
