import 'dart:io';
import 'dart:convert';

import 'package:path/path.dart' as path;
import 'package:http/http.dart' as http;

import 'base.dart';

const _baseCloneUrl = 'https://github.com/endaft/';
const _baseSearchUrl = 'https://api.github.com/search/';
final _templatesUrl = Uri.parse(
  '${_baseSearchUrl}repositories?q=org:endaft template in:name',
);

class TemplateTask extends TaskCommand {
  TemplateTask(EnDaftCommand parent, Logger logger)
      : super(parent, logger, TaskRequirements());

  static String taskName = 'template';

  final List<String> templates = [];

  @override
  String get name => TemplateTask.taskName;

  @override
  String get description => 'Handles template selection and installation.';

  String? get templateName => args['template'];

  int _getAnswerInt(int min, int max) {
    while (true) {
      final input = stdin.readLineSync() ?? '';
      final value = int.tryParse(input) ?? -1;
      if (value >= min && value <= max) {
        return value;
      }
    }
  }

  Future<String?> _selectTemplate() async {
    // Pull template list from GitHub org
    final options = await _getTemplateList();

    // Display selection list
    int counter = 0;
    logger.printLine();
    for (var template in options) {
      logger.printLine('      ${++counter} ▶ $template');
    }
    logger.printLine();
    logger.printRaw('      Select a template: ');
    final answer = _getAnswerInt(0, options.length);
    final template = options[answer - 1];
    logger.useMemo(template);

    // Set template from selection
    return template;
  }

  Future<List<String>> _getTemplateList() async {
    if (templates.isEmpty) {
      final client = http.Client();
      final available = await client.get(_templatesUrl).then((r) =>
          (jsonDecode(r.body)["items"] as List<dynamic>)
              .map<String>((e) => e['name'].toString()));
      templates.addAll(available);
    }
    return templates;
  }

  Future<String?> _downloadTemplate({required String name}) async {
    final tempDir = Utils.getTempPath();
    final templateRepoUrl = '$_baseCloneUrl$name';
    final closer = logger.printFixed("   👀 Downloading template");
    final args = ['clone', '--depth', '1', templateRepoUrl, tempDir];
    final gitResult = Process.runSync('git', args, workingDirectory: rootDir);
    final result = gitResult.exitCode == 0;

    if (!result) {
      Directory(tempDir).deleteSync(recursive: true);
      logger.printFailed('Failed to download template.', '   ');
    }

    return closer(result) ? tempDir : null;
  }

  Future<bool> _deleteTemplateLocal({required String tempDir}) async {
    final localDir = Directory(tempDir);
    if (localDir.existsSync()) {
      localDir.deleteSync(recursive: true);
    }
    return true;
  }

  Future<bool> _deployTemplateFiles({required String tempDir}) async {
    final template = Directory(tempDir);
    final fileSet = template.listSync(recursive: true);
    for (final file in fileSet.whereType<File>()) {
      final relPath = path.relative(file.absolute.path, from: tempDir);
      if (relPath.startsWith('.git')) continue;

      final destPath = path.absolute(rootDir, relPath);
      if (!File(destPath).existsSync()) {
        final destDir = Directory(path.dirname(destPath));
        if (!destDir.existsSync()) destDir.createSync(recursive: true);
        file.copySync(destPath);
      }
    }
    return true;
  }

  Future<bool> _installTemplate() async {
    final installScriptPath = path.join(rootDir, 'shared/bin/install.dart');
    if (File(installScriptPath).existsSync()) {
      final args = ['run', ':install'];
      final installResult = Process.runSync(
        'dart',
        args,
        workingDirectory: rootDir,
      );
      final result = installResult.exitCode == 0;
      if (!result) {
        logger.printFailed(installResult.stderr.toString());
      }
      return result;
    }
    logger.printInfo('No template installer found.');
    return false;
  }

  @override
  Future<bool> run() async {
    // Check for template param
    String? tempName = templateName;
    final needsTemplate = tempName?.isEmpty ?? true;
    final closer = logger.printFixed("   👀 Checking templates");

    // If no template was specified
    if (needsTemplate) {
      tempName = await _selectTemplate();
      if (tempName == null || tempName.isEmpty) {
        return false; // Fail out, cannot proceed without a template
      }
    }

    // Validate provided template exists in list
    final tempList = await _getTemplateList();
    if (!tempList.contains(tempName)) {
      return false; // Fail out, cannot proceed with an invalid template
    }

    // Download selected template to temp dir
    final tempDir = await _downloadTemplate(name: tempName!);
    if (tempDir == null || tempDir.isEmpty) {
      return closer(false, 'Template download failed.');
    }

    // Deploy without overwriting existing files
    await _deployTemplateFiles(tempDir: tempDir);

    // Run the template installer
    await _installTemplate();

    // Delete temp dir and template repo
    if (tempDir.isNotEmpty) {
      await _deleteTemplateLocal(tempDir: tempDir);
    }

    return closer(true, tempName);
  }
}
