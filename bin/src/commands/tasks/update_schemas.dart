import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;

import 'base.dart';

class UpdateSchemasTask extends TaskCommand {
  UpdateSchemasTask(EnDaftCommand parent, Logger logger)
      : super(parent, logger, TaskRequirements());

  static String taskName = 'update-schemas';

  @override
  String get name => UpdateSchemasTask.taskName;

  @override
  String get description =>
      'Updates IaC.json file to reference their correct schemas.';

  final inRs = '   ';

  @override
  Future<bool> run() async {
    final List<String> errors = [];
    final closer = logger.fixed('📝 Writing schema references');
    final schemasDir = Utils.pathFromRoot(KnownPaths.schemas, rootDir);

    await Utils.findFiles(matcher: RegExps.fileIaCJson).listen((file) {
      try {
        final schemaName = file.path.contains('/lambdas/')
            ? 'iac.lambda.schema.json'
            : 'iac.shared.schema.json';
        final relSchemaPath = path.relative(schemasDir, from: file.parent.path);
        final iacJson = jsonDecode(file.readAsStringSync());
        iacJson[r'$schema'] = path.join(relSchemaPath, schemaName);
        file.writeAsStringSync(JsonEncoder.withIndent('  ').convert(iacJson));
      } on FileSystemException catch (e) {
        errors.add(
          "${e.message} → ${path.relative(e.path ?? file.path, from: rootDir)}",
        );
      }
    }).asFuture();

    final result = closer(errors.isEmpty);
    for (var error in errors) {
      logger.error(error);
    }

    return logger.close(result)!;
  }
}
