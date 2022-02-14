import 'tasks/all.dart';

class ValidateCommand extends EnDaftCommand {
  @override
  final name = "validate";

  @override
  final description =
      "Validates your solution state and settings for deployment readiness.";

  @override
  String get category => 'General';

  ValidateCommand(Logger logger) : super(logger: logger, tools: []);

  @override
  List<TaskCommand> revealTasks() => [ValidateJsonTask(this, logger)];

  @override
  Future<bool> run() async {
    final closure = logger.memo("Validate");
    useSequence([ValidateJsonTask(this, childLogger())]);
    final result = await runSequence();
    return logger.close(closure(result))!;
  }
}
