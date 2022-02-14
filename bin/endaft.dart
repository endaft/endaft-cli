import 'package:args/command_runner.dart';

import 'src/commands/all.dart';
import 'src/log_controller.dart';

void main(List<String> args) async {
  final logController = LogController();
  final rootLogger = logController.rootSlice();
  try {
    final runner = CommandRunner<bool>("endaft",
        "Operations and utilities for the EnDaft (Dart, Flutter, AWS, Terraform) solution templates.",
        usageLineLength: 120)
      ..addCommand(TestCommand(logController.rootSlice()))
      ..addCommand(BuildCommand(logController.rootSlice()))
      ..addCommand(CheckCommand(logController.rootSlice()))
      ..addCommand(SharedCommand(logController.rootSlice()))
      ..addCommand(LambdaCommand(logController.rootSlice()))
      ..addCommand(DockerCommand(logController.rootSlice()))
      ..addCommand(InstallCommand(logController.rootSlice()))
      ..addCommand(ValidateCommand(logController.rootSlice()))
      ..addCommand(AggregateCommand(logController.rootSlice()));
    await runner.run(args);
  } on UsageException catch (e) {
    rootLogger.printLine(e.message, false);
    rootLogger.printLine(e.usage, false);
  }
}
