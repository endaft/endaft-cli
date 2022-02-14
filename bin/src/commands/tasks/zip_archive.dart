import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as path;

import 'base.dart';

class ZipArchiveTask extends TaskCommand {
  ZipArchiveTask(EnDaftCommand parent, Logger logger)
      : super(parent, logger, TaskRequirements());

  static String taskName = 'zip-archive';

  @override
  String get name => ZipArchiveTask.taskName;

  @override
  String get description =>
      'Compresses file system entities into a zip archive.';

  List<String> get inputPaths => argResults!['input'].toString().split(',');

  String get outZipPath => argResults!['output'].toString();

  String get zipName => path.basename(outZipPath);

  @override
  Future<bool> run() async {
    var result = true;
    try {
      final zip = ZipFileEncoder()..create(outZipPath);
      for (final inputPath in inputPaths) {
        final baseName = path.basename(inputPath);
        final isDir = FileSystemEntity.isDirectorySync(inputPath);
        final closer = logger.fixed(
          '📦 Packing ${baseName.green()} → ${zipName.green()}',
        );
        if (isDir) {
          zip.addDirectory(Directory(inputPath));
        } else {
          zip.addFile(File(inputPath));
        }
        result = closer(result);
      }
      zip.close();
    } catch (e) {
      logger.error(e.toString());
      result = false;
    }

    return logger.close(result)!;
  }
}
