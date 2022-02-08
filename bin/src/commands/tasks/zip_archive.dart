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

  final inRs = '   ';

  @override
  Future<bool> run() async {
    bool result = true;
    final inputPaths = args['input'].toString().split(',');
    final outZipPath = args['output'].toString();
    final ind = (args['indent'] ?? inRs).toString();
    final zipName = path.basename(outZipPath);

    try {
      final zip = ZipFileEncoder()..create(outZipPath);
      for (var inputPath in inputPaths) {
        final baseName = path.basename(inputPath);
        final isDir = FileSystemEntity.isDirectorySync(inputPath);
        final closer = logger.printFixed(
            '📦 Packing ${baseName.green()} → ${zipName.green()}', ind);
        if (isDir) {
          zip.addDirectory(Directory(inputPath));
        } else {
          zip.addFile(File(inputPath));
        }
        result = closer(result);
      }
      zip.close();
    } catch (e) {
      logger.useMemo(e.toString());
      result = false;
    }

    return result;
  }
}
