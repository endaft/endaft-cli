import 'package:args/command_runner.dart';

// ignore: avoid_relative_lib_imports
import '../lib/endaft.dart';

void main(List<String> args) async {
  final logger = Logger();
  try {
    final runner = CommandRunner<bool>("endaft",
        "Operations and utilities for the EnDaft (Dart, Flutter, AWS, Terraform) solution templates.",
        usageLineLength: 120)
      ..addCommand(TestCommand(logger))
      ..addCommand(BuildCommand(logger))
      ..addCommand(CheckCommand(logger))
      ..addCommand(SharedCommand(logger))
      ..addCommand(LambdaCommand(logger))
      ..addCommand(DockerCommand(logger))
      ..addCommand(InstallCommand(logger))
      ..addCommand(ValidateCommand(logger))
      ..addCommand(AggregateCommand(logger));
    await runner.run(args);
  } on UsageException catch (e) {
    logger.printFailed(e.message);
    logger.printLine(e.usage);
  }
}
