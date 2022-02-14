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

  bool get useFix => args['fix'] ?? false;

  @override
  Future<bool> run() async {
    final List<FileRequirement> fsPaths = parent.globalFsPaths;

    List<bool> results = [];
    for (var fsp in fsPaths) {
      final name = path.basename(fsp.path);
      final closure = logger.memo('📂 Checking for ${name.green()}');
      final file = File(fsp.path);
      bool exists = file.existsSync();
      String reason = '';
      if (!exists && useFix && fsp.canCreate) {
        exists = fsp.creator!(file: file);
      } else {
        reason = 'can fix';
      }
      results.add(closure(exists, reason: reason));
    }

    final result = results.every((r) => r);
    return logger.close(result)!;
  }
}
