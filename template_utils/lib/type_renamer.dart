import 'dart:io';

import 'package:recase/recase.dart';
import 'package:template_utils/file_utils.dart';
import 'package:template_utils/replacements_utils.dart';

Future<void> renameTpe({
  required String rootPath,
  required String oldFilePath,
  required String newFilePath,
  required String newTypeName,
  required String oldTypeName,
}) async {
  File(newFilePath).parent.createSync(recursive: true);
  File(oldFilePath).renameSync(newFilePath);
  final oldFeatureName = oldFilePath.featureName;
  final newFeatureName = newFilePath.featureName;
  final oldTypeName = oldFilePath.classNameFromFile;
  final newTypeName = newFilePath.classNameFromFile;
  final oldMocksFile = mocksFilePath(feature: oldFeatureName, rootDir: rootPath);
  final newMocksFile = mocksFilePath(feature: newFeatureName, rootDir: rootPath);
  final appPackage = await getAppPackage(rootPath);
  var oldVariableName = oldTypeName.camelCase;
  var newVariableName = newTypeName.camelCase;
  print("STARTING REPLACING IN FILES");
  await for (final file in allProjectDartFiles(rootDir: rootPath)) {
    var hasMockMatch = false;
    await replaceAllInFileLineByLine(filePath: file.path, replacements: [
      //Class name
      StringReplacement(
        from: RegExp("([^a-zA-Z])${oldTypeName}"),
        to: (match) => "${match.group(1)}${newTypeName}",
        failIfNotFound: false,
      ),
      // remove old mocks registration
      if (oldFeatureName != newFeatureName) ...[
        StringReplacement.string(
          from: templateMockStaticField(oldTypeName),
          to: '',
          failIfNotFound: false,
        ),
        StringReplacement(
          from: "${oldMocksFile.classNameFromFile}.$oldVariableName",
          to: (match) {
            hasMockMatch = true;
            return '${newMocksFile.classNameFromFile}.${newVariableName}';
          },
          failIfNotFound: false,
        ),
        StringReplacement.string(
          from: templateMockFieldInit(oldTypeName),
          to: '',
          failIfNotFound: false,
        ),
        StringReplacement.string(
          from: templateRegisterFallback(oldTypeName),
          to: '',
          failIfNotFound: false,
        ),
      ],
      // replace all variables
      StringReplacement(
        from: RegExp("([^a-zA-Z])${oldVariableName}"),
        to: (match) => "${match.group(1)}${newVariableName}",
        failIfNotFound: false,
      ),
      // replace all import paths
      StringReplacement.string(
        from: oldFilePath.importPath(rootPath, appPackage: appPackage),
        to: newFilePath.importPath(rootPath, appPackage: appPackage),
        failIfNotFound: false,
      ),
    ]);
    if (oldFeatureName != newFeatureName && hasMockMatch) {
      print("REPLACING MOCK MATCHES");
      // adds new mocks file import to the file only if the old mock was used in the file (i.e: `Mocks.authRepository`)
      await replaceAllInFileLineByLine(
        filePath: file.absolute.path,
        replacements: [
          StringReplacement(
            from: RegExp('import .*\/${File(oldMocksFile).fileNameWithExtension}.*'),
            to: (match) => "${match[0]}\n${match[0]?.replaceAll(
              "/mocks/${File(oldMocksFile).fileNameWithExtension}",
              "/features/$newFeatureName/mocks/${File(newMocksFile).fileNameWithExtension}",
            )}",
            failIfNotFound: false,
          ),
        ],
      );
    }
  }
  print("DONE REPLACING IN FILES");
  final newFeatureComponentPath = featureComponentFilePath(feature: newFeatureName, rootDir: rootPath);
  final oldFeatureComponentPath = featureComponentFilePath(feature: oldFeatureName, rootDir: rootPath);
  print("OLD COMPONENT PATH: $oldFeatureComponentPath");
  print("NEW COMPONENT PATH: $newFeatureComponentPath");
  print("COMPONENT EXISTS: ${File(newFeatureComponentPath).existsSync()}");
  if (newFeatureComponentPath != oldFeatureComponentPath && File(newFeatureComponentPath).existsSync()) {
    print("REPLACING FACTORIES...");
    final factories = <String, String>{};

    /// remove old factories
    var regex = getItFactoryRegex(newTypeName);
    print("looking for factory: $regex ...");
    await replaceAllInFileAtOnce(filePath: oldFeatureComponentPath, replacements: [
      StringReplacement(
        from: regex,
        to: (match) {
          print("FOUND MATCH: ${match[1]}");
          final allGroups = match.groups(List.generate(match.groupCount, (index) => index + 1));

          /// retrieves '//DO-NOT-REMOVE' comment before which the factory was registered
          final comment = allGroups.firstWhere((element) => (element ?? '').trim().startsWith(RegExp(r"//\s*DO")))!;

          /// match[1] contains the factory code
          factories[comment] = match[1]!;

          /// remove just factory from result, leaving everything else
          return allGroups.sublist(1).map((e) => e ?? '').join("");
        },
        failIfNotFound: false,
      ),
    ]);

    /// add new factories
    await replaceAllInFileAtOnce(
      filePath: newFeatureComponentPath,
      replacements: factories.entries
          .map((entry) => StringReplacement.prepend(
                before: entry.key,
                text: entry.value,
              ))
          .toList(),
    );
  }
}
