import 'tasks/all.dart';
import 'tasks/template.dart';

class InstallCommand extends EnDaftCommand {
  @override
  final name = "install";

  @override
  final description =
      "Installs the required Dockerfile, schema files, and updates the IaC JSON files to use the appropriate schemas.";

  @override
  String get category => 'General';

  InstallCommand(Logger logger) : super(logger: logger, tools: []);

  @override
  List<TaskCommand> revealTasks() => [
        GitStatusTask(this, logger),
        TemplateTask(this, logger),
        /* InstallEnDaftFilesTask(this, logger),
        UpdateSchemasTask(this, logger), */
      ];

  @override
  Future<bool> run() async {
    final blockLogger = logger.headerBlock("Install");
    useSequence([
      GitStatusTask(this, blockLogger),
      TemplateTask(this, blockLogger),
      /* InstallEnDaftFilesTask(this, blockLogger),
      UpdateSchemasTask(this, blockLogger), */
    ]);
    final result = await runSequence({
      GitStatusTask.taskName: {'root': rootDir},
      TemplateTask.taskName: {'root': rootDir}
    });

    return blockLogger.close(result);
  }
}
