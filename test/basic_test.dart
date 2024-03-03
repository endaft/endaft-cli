import 'dart:io';

import 'package:test/test.dart';

final testDir = Directory.current.path;

String formatOutput(int value) {
  return "\x1B[37m\x1B[100;1m covered \x1B[0m\x1B[0m\x1B[30m\x1B[42m $value% \x1B[0m\x1B[0m";
}

void main() {
  group('Basic Tests', () {
    test('Prints Help As Expected', () {
      final args = ["endaft", "-h"];
      final result = Process.runSync("dart", ["run", ...args]);
      final line = result.stdout
          .toString()
          .split("\n")
          .where((e) => e.trim().isNotEmpty)
          .join("\n");

      expect(
          line,
          contains(
              'Operations and utilities for the EnDaft (Dart, AWS, Flutter, Terraform) solution templates.'));
      expect(
          line,
          contains(
              'Run "endaft help <command>" for more information about a command.'));
    });
  });
}
