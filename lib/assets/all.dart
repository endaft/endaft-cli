import 'dart:io';

import '../utils.dart';
import 'schema_lambda.dart';
import 'schema_shared.dart';
import 'docker_al2.dart';
import 'run_sh.dart';

/// Represents a collection of known assets
class Assets {
  /// The lambda IaC JSON schema
  static AssetString get schemaLambda => AssetString.from(
      iacLambdaSchema, '.endaft/schemas/iac.lambda.schema.json');

  /// The shared IaC JSON schema
  static AssetString get schemaShared => AssetString.from(
      iacSharedSchema, '.endaft/schemas/iac.shared.schema.json');

  /// The Amazon Linux 2 dockerfile for building
  static AssetString get dockerAmznL2 =>
      AssetString.from(dockerAmznLinux2, '.endaft/Dockerfile.al2');

  /// The `run.sh` file used in the docker container
  static AssetString get dockerRunScript =>
      AssetString.from(dockerRunSh, '.endaft/run.sh');
}

/// Represents a string-base asset
class AssetString {
  AssetString._privateConstructor(this._contents, this.targetPath);

  final String _contents;

  final String targetPath;

  /// Creates a new [AssetString] with the provided [content].
  factory AssetString.from(String content, String targetPath) {
    return AssetString._privateConstructor(content, targetPath);
  }

  /// Write the asset content to the specified [file], or the [targetPath] if
  /// null, optionally setting permissions specified in [chmod]. If the file
  /// exists and [noClobber] is `true`, specified permissions will still be set
  /// but the file won't be overwritten.
  bool writeTo({File? file, String? chmod, bool noClobber = false}) {
    final safeFile = file ?? File(targetPath);
    if (!safeFile.parent.existsSync()) {
      safeFile.parent.createSync(recursive: true);
    }
    if (!noClobber || !safeFile.existsSync()) {
      safeFile.writeAsStringSync(_contents);
    }
    if (chmod != null) {
      Utils.chmod(chmod, safeFile.path);
    }
    return safeFile.existsSync();
  }

  /// Returns the underlying content of the asset as a [String].
  @override
  String toString() {
    return _contents;
  }
}
