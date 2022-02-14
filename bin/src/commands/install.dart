import 'tasks/all.dart';

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
        InstallEnDaftFilesTask(this, logger),
        UpdateSchemasTask(this, logger),
      ];

  @override
  Future<bool> run() async {
    final closure = logger.memo("Install");
    useSequence([
      InstallEnDaftFilesTask(this, childLogger()),
      UpdateSchemasTask(this, childLogger()),
    ]);
    final result = await runSequence();

    return logger.close(closure(result))!;
  }
}
