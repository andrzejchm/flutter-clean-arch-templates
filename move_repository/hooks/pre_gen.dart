import 'dart:io';

import "package:mason/mason.dart";
import "package:recase/recase.dart";
import 'package:template_utils/file_utils.dart';

Future<void> run(HookContext context) async {
  final appPackage = "picnic_app";
  final rootPath = Directory.current.parent.absolute.path.suffixed(Platform.pathSeparator);
  final libDir = Directory("${rootPath}lib");
  final testDir = Directory("${rootPath}test");

  final oldInterfacePath = File("${rootPath}${context.vars["interface_path"]}");
  final oldImplementationPath = File("${rootPath}${context.vars["implementation_path"]}");
  if (!oldInterfacePath.existsSync()) {
    throw "Cannot find old repository at ${oldInterfacePath.absolute}";
  }
  if (!oldImplementationPath.existsSync()) {
    throw "Cannot find old repository at ${oldImplementationPath.absolute}";
  }

  final newFeatureName = (context.vars["new_feature_name"] as String? ?? '').snakeCase;
  final oldFeatureName = oldInterfacePath.path.contains("lib/features")
      ? RegExp("lib/features/(.+)/").firstMatch(oldInterfacePath.path)?.group(1) ?? ""
      : "";
  final newRepositoryName = context.vars["new_repository_name"] as String? ?? "";
  final newRepositoryPrefix = context.vars["new_repository_prefix"] as String? ?? '';

  final oldInterfaceFileName = oldInterfacePath.fileNameWithExtension;
  final oldImplementationFileName = oldImplementationPath.fileNameWithExtension;

  final newInterfaceFileName =
      newRepositoryName.isEmpty ? oldInterfaceFileName : "${newRepositoryName.suffixed("Repository").snakeCase}.dart";

  final newImplementationFileName = newRepositoryPrefix.isEmpty && newRepositoryName.isEmpty
      ? oldImplementationFileName
      : "${newRepositoryPrefix.snakeCase}_$newInterfaceFileName";

  final newInterfacePath = File(newFeatureName.isEmpty
      ? '${rootPath}lib/core/domain/repositories/$newInterfaceFileName'
      : '${rootPath}lib/features/${newFeatureName.snakeCase}/domain/repositories/$newInterfaceFileName');

  final newImplementationPath = File(newFeatureName.isEmpty
      ? '${rootPath}lib/core/data/$newImplementationFileName'
      : '${rootPath}lib/features/${newFeatureName.snakeCase}/data/$newImplementationFileName');

  final oldInterfaceName = oldInterfaceFileName.removedFileExtension.pascalCase;
  final oldImplementationName = oldImplementationFileName.removedFileExtension.pascalCase;
  final newInterfaceName = newInterfaceFileName.removedFileExtension.pascalCase;
  final newImplementationName = newImplementationFileName.removedFileExtension.pascalCase;

  final oldInterfacePackage = "package:$appPackage${oldInterfacePath.relativePathTo(libDir)}";
  final oldImplementationPackage = "package:$appPackage${oldImplementationPath.relativePathTo(libDir)}";
  final oldVariableName = oldInterfaceName.camelCase;
  final newInterfacePackage = "package:$appPackage${newInterfacePath.relativePathTo(libDir)}";
  final newImplementationPackage = "package:$appPackage${newImplementationPath.relativePathTo(libDir)}";
  final newVariableName = newInterfaceName.camelCase;

  final oldMockClass = "class Mock$oldInterfaceName extends Mock implements $oldInterfaceName {}";
  final oldMockStaticField = "static late Mock$oldInterfaceName $oldVariableName;";
  final oldMockStaticFieldInit = "$oldVariableName = Mock$oldInterfaceName();";
  final oldMockFallback = "registerFallbackValue(Mock$oldInterfaceName());";
  final newMockClass = """
  class Mock$newInterfaceName extends Mock implements $newInterfaceName {}
  //DO-NOT-REMOVE REPOSITORIES_MOCK_DEFINITION
  """;

  final newMockImport = """
  import "$newInterfacePackage";
  //DO-NOT-REMOVE IMPORTS_MOCK_DEFINITIONS
  """;

  final newMockStaticField = """
  static late Mock$newInterfaceName $newVariableName;
  //DO-NOT-REMOVE REPOSITORIES_MOCKS_STATIC_FIELD
  """;

  final newMockStaticFieldInit = """
  $newVariableName = Mock$newInterfaceName();
  //DO-NOT-REMOVE REPOSITORIES_INIT_MOCKS
  """;

  final newMockFallback = """
  registerFallbackValue(Mock$newInterfaceName());
  //DO-NOT-REMOVE REPOSITORIES_MOCK_FALLBACK_VALUE
  """;

  try {
    final oldMocksFile = mocksFilePath(oldFeatureName);
    final oldMocksFileClass = File(oldMocksFile).fileNameWithoutExtension.pascalCase;
    final newMocksFile = mocksFilePath(newFeatureName);
    final newMocksFileClass = File(newMocksFile).fileNameWithoutExtension.pascalCase;

    Future<void> replaceInAllFiles(Stream<File> files) async {
      await for (final file in files) {
        ///captures whether old mock usage was found in file, i.e: (`Mocks.authRepository`)
        var hasMockMatch = false;
        await multiReplaceAllInFile(
          filePath: file.absolute.path,
          replacements: [
            StringReplacement.string(from: oldMockClass, to: '', failIfNotFound: false),
            StringReplacement(
              from: "$oldMocksFileClass.$oldVariableName",
              to: (match) {
                hasMockMatch = true;
                return "$newMocksFileClass.$newVariableName";
              },
              failIfNotFound: false,
            ),
            StringReplacement.string(from: oldMockStaticField, to: '', failIfNotFound: false),
            StringReplacement.string(from: oldMockStaticFieldInit, to: '', failIfNotFound: false),
            StringReplacement.string(from: oldMockFallback, to: '', failIfNotFound: false),
            StringReplacement.string(from: oldImplementationName, to: newImplementationName, failIfNotFound: false),
            StringReplacement.string(from: oldInterfaceName, to: newInterfaceName, failIfNotFound: false),
            StringReplacement.string(from: oldVariableName, to: newVariableName, failIfNotFound: false),
            StringReplacement.string(
                from: oldImplementationPackage, to: newImplementationPackage, failIfNotFound: false),
            StringReplacement.string(from: oldInterfacePackage, to: newInterfacePackage, failIfNotFound: false),
          ],
        );

        if (oldMocksFileClass != newMocksFileClass && hasMockMatch) {
          // adds new mocks file import to the file only if the old mock was used in the file (i.e: `Mocks.authRepository`)
          await multiReplaceAllInFile(
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
    }

    await newInterfacePath.parent.create(recursive: true);
    await newImplementationPath.parent.create(recursive: true);
    await oldInterfacePath.rename(newInterfacePath.absolute.path);
    await oldImplementationPath.rename(newImplementationPath.absolute.path);

    await replaceInAllFiles(libDir.allDartFiles);
    await replaceInAllFiles(testDir.allDartFiles);

    await ensureFeaturesFile(appPackage: appPackage, featureName: newFeatureName);
    await multiReplaceAllInFile(
      filePath: mockDefinitionsFilePath(newFeatureName),
      replacements: [
        StringReplacement.string(from: "//DO-NOT-REMOVE REPOSITORIES_MOCK_DEFINITION", to: newMockClass),
        StringReplacement.string(from: "//DO-NOT-REMOVE IMPORTS_MOCK_DEFINITIONS", to: newMockImport),
      ],
    );
    await multiReplaceAllInFile(
      filePath: newMocksFile,
      replacements: [
        StringReplacement.string(from: "//DO-NOT-REMOVE REPOSITORIES_MOCKS_STATIC_FIELD", to: newMockStaticField),
        StringReplacement.string(from: "//DO-NOT-REMOVE REPOSITORIES_INIT_MOCKS", to: newMockStaticFieldInit),
        StringReplacement.string(from: "//DO-NOT-REMOVE REPOSITORIES_MOCK_FALLBACK_VALUE", to: newMockFallback),
      ],
    );
  } catch (ex, stack) {
    print("EXCEPTION: $ex");
    print("stack: $stack");
    rethrow;
  }
}
