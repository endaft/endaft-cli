import 'dart:io';

import 'base.dart';

class InstallEnDaftFilesTask extends TaskCommand {
  InstallEnDaftFilesTask(EnDaftCommand parent, Logger logger)
      : super(parent, logger, TaskRequirements());

  static String taskName = 'install-endaft-files';

  @override
  String get name => InstallEnDaftFilesTask.taskName;

  @override
  String get description =>
      'Installs folders and files required by other EnDaft commands.';

  final inRs = '   ';

  bool writeSchemaFiles(String rootDir) {
    String? reason;
    bool result = true;
    final closer = logger.printFixed('📝 Writing schema files', inRs);

    try {
      Assets.schemaLambda.writeTo();
      Assets.schemaShared.writeTo();
    } on FileSystemException catch (e) {
      result = false;
      reason = e.message;
    }

    return closer(result, reason);
  }

  bool writeDockerFiles(String rootDir) {
    String? reason;
    bool result = true;
    final closer = logger.printFixed('📝 Writing docker files', inRs);

    try {
      Assets.dockerAmznL2.writeTo(noClobber: true);
      Assets.dockerRunScript.writeTo(chmod: '+x');
    } on FileSystemException catch (e) {
      result = false;
      reason = e.message;
    }

    return closer(result, reason);
  }

  @override
  Future<bool> run() async {
    List<bool> results = [writeDockerFiles(rootDir), writeSchemaFiles(rootDir)];
    final result = results.every((r) => r);
    return result;
  }
}
