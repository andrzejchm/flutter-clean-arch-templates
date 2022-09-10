import 'dart:convert';
import 'dart:io';

import 'package:mason/mason.dart';
import 'package:recase/recase.dart';
import 'package:template_utils/feature_templates.dart';

extension FileUtils on File {
  String get fileNameWithExtension => path.substring(path.lastIndexOf(Platform.pathSeparator) + 1);

  String get fileNameWithoutExtension => fileNameWithExtension.removedFileExtension;

  String relativePathTo(FileSystemEntity entity) => absolute.path.replaceAll(entity.absolute.path, '');
}

extension AddSuffix on String {
  String suffixed(String suffix) {
    if (endsWith(suffix)) {
      return this;
    } else {
      return "${this}$suffix";
    }
  }

  String get removedFileExtension => substring(0, lastIndexOf("."));
}

extension DartFilesInDir on Directory {
  Stream<File> get allDartFiles =>
      this.list(recursive: true).where((it) => it is File && it.path.endsWith(".dart")).map((event) => event as File);
}

String featureComponentFilePath(String? feature) => ((feature?.isEmpty ?? true) || feature == 'core') //
    ? '../lib/dependency_injection/app_component.dart'
    : '../lib/features/$feature/dependency_injection/feature_component.dart';

String mockDefinitionsFilePath(String? feature) => ((feature?.isEmpty ?? true) || feature == 'core') //
    ? '../test/mocks/mock_definitions.dart'
    : '../test/features/$feature/mocks/${feature}_mock_definitions.dart';

String mocksFilePath(String? feature) => ((feature?.isEmpty ?? true) || feature == 'core') //
    ? '../test/mocks/mocks.dart'
    : '../test/features/$feature/mocks/${feature}_mocks.dart';

String pagesTestConfigPath(String feature) => '../test/features/$feature/pages/flutter_test_config.dart';

/// makes sure the feature-specific getIt registration index file is created,
/// if its not, creates one and registers in master `app_component.dart` file
Future<void> ensureFeatureComponentFile({
  required String appPackage,
  required String? feature,
}) async {
  var featurePath = featureComponentFilePath(feature);
  var filePackage = featurePath.replaceAll("../lib/features/", "");
  final featureFile = File(featurePath);
  final coreFile = File(featureComponentFilePath(null));
  if (!await featureFile.exists()) {
    await featureFile.create(recursive: true);
    await writeToFile(filePath: featureFile.path, text: featureComponentTemplate(appPackage));
    await replaceAllInFile(
      filePath: coreFile.path,
      from: "//DO-NOT-REMOVE APP_COMPONENT_IMPORTS",
      to: """
import 'package:$appPackage/features/$filePackage' as $feature;
//DO-NOT-REMOVE APP_COMPONENT_IMPORTS
      """,
    );
    await replaceAllInFile(
      filePath: coreFile.path,
      from: "//DO-NOT-REMOVE FEATURE_COMPONENT_INIT",
      to: """
$feature.configureDependencies();
//DO-NOT-REMOVE FEATURE_COMPONENT_INIT
      """,
    );
  }
}

Future<void> ensureFeaturesFile({
  required String appPackage,
  required String featureName,
}) async {
  await ensureFeatureComponentFile(appPackage: appPackage, feature: featureName);
  await ensureMockDefinitionsFile(featureName);
  await ensureMocksFile(featureName);
}

/// makes sure the feature-specific mock definitions file is created, if its not, creates one
Future<void> ensureMockDefinitionsFile(
  String? feature, {
  HookContext? context,
}) async {
  var featurePath = mockDefinitionsFilePath(feature);
  final featureFile = File(featurePath).absolute;
  final coreFile = File(mockDefinitionsFilePath(null)).absolute;
  context?.logger.write("feature mocks file: ${featureFile.path}");
  context?.logger.write("core file: ${coreFile.path}");
  if (!await featureFile.exists()) {
    await featureFile.create(recursive: true);
    await writeToFile(filePath: featureFile.path, text: featureMockDefinitionsTemplate);
  }
}

/// makes sure the feature-specific mocks file is created,
/// if its not, creates one and registers in master `mocks.dart` file
Future<void> ensureMocksFile(
  String? feature, {
  HookContext? context,
}) async {
  var featurePath = mocksFilePath(feature);
  var filePackage = featurePath.replaceAll("../test/", "../");
  final featureFile = File(featurePath);
  final coreFile = File(mocksFilePath(null));
  await _ensurePageTestConfigFile(feature);
  if (!await featureFile.exists()) {
    await featureFile.create(recursive: true);
    await writeToFile(filePath: featureFile.path, text: featureMocksTemplate(feature!));
    await replaceAllInFile(
      filePath: coreFile.path,
      from: "//DO-NOT-REMOVE IMPORTS_MOCKS",
      to: """
import '$filePackage';
//DO-NOT-REMOVE IMPORTS_MOCKS
      """,
    );
    await replaceAllInFile(
      filePath: coreFile.path,
      from: "//DO-NOT-REMOVE FEATURE_MOCKS_INIT",
      to: """
${feature.pascalCase}Mocks.init();
//DO-NOT-REMOVE FEATURE_MOCKS_INIT
      """,
    );
  }
}

Future<void> _ensurePageTestConfigFile(String? feature) async {
  if (feature == null || feature.isEmpty) {
    return;
  }
  final testConfigFile = File(pagesTestConfigPath(feature)).absolute;

  if (!await testConfigFile.exists()) {
    await testConfigFile.create(recursive: true);
    await writeToFile(filePath: testConfigFile.path, text: featurePageTestConfigTemplate);
  }
}

/// performs multiple replacements in single file, convienient method so that you dont have to read file
/// multiple times to perform replacements.
///
/// replacements are performed line-by-line in the order they were specified in the list
///
/// IMPORTANT: Does not support multiline replacements as all replacements are applied on per-line basis
Future<void> multiReplaceAllInFile({
  required String filePath,
  required List<StringReplacement> replacements,
}) async {
  final tmpFilePath = "${filePath}_write_.tmp";
  final tmpFile = File(tmpFilePath);

  IOSink? writeSink;
  try {
    final readStream = readFileLines(filePath);
    writeSink = tmpFile.openWrite();
    final foundReplacementsMap = Map.fromEntries(replacements.map((e) => MapEntry(e, false)));
    await for (final line in readStream) {
      var newLine = line;
      for (final rep in replacements) {
        if (line.contains(rep.from)) {
          foundReplacementsMap[rep] = true;
          newLine = newLine.replaceAllMapped(rep.from, rep.to);
        }
      }
      writeSink.writeln(newLine);
    }
    final notFoundReplacements =
        foundReplacementsMap.entries.where((element) => element.key.failIfNotFound && !element.value);
    if (notFoundReplacements.isNotEmpty) {
      var notFoundReplacementsList = foundReplacementsMap.entries.map((entry) => entry.key.from).join("\n");
      throw "couldn't find following replacements: $notFoundReplacementsList";
    }
  } catch (ex) {
    tmpFile.deleteSync();
    rethrow;
  } finally {
    await writeSink?.close();
  }

  await tmpFile.rename(filePath);
}

Future<void> replaceAllInFile({
  required String filePath,
  required String from,
  required String to,
  bool failIfNotFound = true,
}) async =>
    multiReplaceAllInFile(
      filePath: filePath,
      replacements: [
        StringReplacement.string(
          from: from,
          to: to,
          failIfNotFound: failIfNotFound,
        )
      ],
    );

Future<void> writeToFile({
  required String filePath,
  required String text,
}) async {
  final tmpFilePath = "${filePath}_write_.tmp";
  final tmpFile = File(tmpFilePath);

  try {
    await tmpFile.writeAsString(text);
  } catch (ex) {
    tmpFile.deleteSync();
    rethrow;
  }

  await tmpFile.rename(filePath);
}

Stream<String> readFileLines(String path) =>
    File(path).openRead().transform(utf8.decoder).transform(const LineSplitter());

void main() {
  ensureMockDefinitionsFile("sample_feature");
}

class StringReplacement {
  final Pattern from;
  final String Function(Match match) to;
  final bool failIfNotFound;

  const StringReplacement({
    required this.from,
    required this.to,
    this.failIfNotFound = true,
  });

  factory StringReplacement.string({
    required Pattern from,
    required String to,
    bool failIfNotFound = true,
  }) {
    return StringReplacement(
      from: from,
      to: (_) => to,
      failIfNotFound: failIfNotFound,
    );
  }
}
