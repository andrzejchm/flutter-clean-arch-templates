import 'dart:io';

import "package:mason/mason.dart";
import 'package:path/path.dart' as path;
import "package:recase/recase.dart";
import 'package:template_utils/template_utils.dart';

Future<void> run(HookContext context) async {
  final rootDir = projectRootDir(context.vars["root_folder_path"] as String? ?? '');
  final appPackage = await getAppPackage(rootDir);
  final libDir = rootDir.libDir;
  final testDir = rootDir.testDir;

  final oldInterfacePath = File(path.join(rootDir, context.vars["interface_path"]));
  final oldImplementationPath = File(path.join(rootDir, context.vars["implementation_path"]));
  if (!oldInterfacePath.existsSync()) {
    throw "Cannot find old repository at ${oldInterfacePath.absolute}";
  }
  if (!oldImplementationPath.existsSync()) {
    throw "Cannot find old repository at ${oldImplementationPath.absolute}";
  }

  final newFeatureName = (context.vars["new_feature_name"] as String? ?? '').snakeCase;
  final newRepositoryName = context.vars["new_repository_name"] as String? ?? "";
  final newRepositoryPrefix = context.vars["new_repository_prefix"] as String? ?? '';

  final oldFeatureName = oldInterfacePath.path.featureName;
  final oldInterfaceFileName = oldInterfacePath.fileNameWithExtension;
  final oldImplementationFileName = oldImplementationPath.fileNameWithExtension;

  final newInterfaceFileName =
      newRepositoryName.isEmpty ? oldInterfaceFileName : "${newRepositoryName.suffixed("Repository").snakeCase}.dart";

  final newImplementationFileName = newRepositoryPrefix.isEmpty && newRepositoryName.isEmpty
      ? oldImplementationFileName
      : "${newRepositoryPrefix.snakeCase}_$newInterfaceFileName";

  final newInterfacePath = File(
    newFeatureName.isEmpty
        ? path.join(libDir, 'core/domain/repositories/$newInterfaceFileName')
        : path.join(libDir, 'features/${newFeatureName.snakeCase}/domain/repositories/$newInterfaceFileName'),
  );

  final newImplementationPath = File(
    newFeatureName.isEmpty
        ? path.join(libDir, 'core/data/$newImplementationFileName')
        : path.join(libDir, 'features/${newFeatureName.snakeCase}/data/$newImplementationFileName'),
  );

  final oldInterfaceName = oldInterfaceFileName.removedFileExtension.pascalCase;
  final oldImplementationName = oldImplementationFileName.removedFileExtension.pascalCase;
  final newInterfaceName = newInterfaceFileName.removedFileExtension.pascalCase;
  final newImplementationName = newImplementationFileName.removedFileExtension.pascalCase;

  final oldInterfacePackage = "package:$appPackage/${libDir.relativePathTo(oldInterfacePath.path)}";
  final oldImplementationPackage = "package:$appPackage/${libDir.relativePathTo(oldImplementationPath.path)}";
  final oldVariableName = oldInterfaceName.camelCase;
  final newInterfacePackage = "package:$appPackage/${libDir.relativePathTo(newInterfacePath.path)}";
  final newImplementationPackage = "package:$appPackage/${libDir.relativePathTo(newImplementationPath.path)}";
  final newVariableName = newInterfaceName.camelCase;

  try {
    final oldMocksFile = mocksFilePath(feature: oldFeatureName, rootDir: rootDir);
    final oldMocksFileClass = File(oldMocksFile).fileNameWithoutExtension.pascalCase;
    final newMocksFile = mocksFilePath(feature: newFeatureName, rootDir: rootDir);
    final newMocksFileClass = File(newMocksFile).fileNameWithoutExtension.pascalCase;

    Future<void> replaceInAllFiles(Stream<File> files) async {
      await for (final file in files) {
        ///captures whether old mock usage was found in file, i.e: (`Mocks.authRepository`)
        var hasMockMatch = false;
        await multiReplaceAllInFile(
          filePath: file.absolute.path,
          replacements: [
            StringReplacement.string(
                from: templateMockClassDefinition(oldInterfaceName), to: '', failIfNotFound: false),
            StringReplacement(
              from: "$oldMocksFileClass.$oldVariableName",
              to: (match) {
                hasMockMatch = true;
                return "$newMocksFileClass.$newVariableName";
              },
              failIfNotFound: false,
            ),
            StringReplacement.string(from: templateMockStaticField(oldInterfaceName), to: '', failIfNotFound: false),
            StringReplacement.string(from: templateMockFieldInit(oldInterfaceName), to: '', failIfNotFound: false),
            StringReplacement.string(from: templateRegisterFallback(oldInterfaceName), to: '', failIfNotFound: false),
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

    await replaceInAllFiles(Directory(libDir).allDartFiles);
    await replaceInAllFiles(Directory(testDir).allDartFiles);

    await ensureFeaturesFile(appPackage: appPackage, featureName: newFeatureName, rootDir: rootDir);
    await multiReplaceAllInFile(
      filePath: mockDefinitionsFilePath(feature: newFeatureName, rootDir: rootDir),
      replacements: [
        StringReplacement.prepend(
          before: "//DO-NOT-REMOVE REPOSITORIES_MOCK_DEFINITION",
          text: templateMockClassDefinition(newInterfaceName),
        ),
        StringReplacement.prepend(
          before: "//DO-NOT-REMOVE IMPORTS_MOCK_DEFINITIONS",
          text: templateImport(newInterfacePackage),
        ),
      ],
    );
    await multiReplaceAllInFile(
      filePath: newMocksFile,
      replacements: [
        StringReplacement.prepend(
          before: "//DO-NOT-REMOVE REPOSITORIES_MOCKS_STATIC_FIELD",
          text: templateMockStaticField(newInterfaceName),
        ),
        StringReplacement.prepend(
          before: "//DO-NOT-REMOVE REPOSITORIES_INIT_MOCKS",
          text: templateMockFieldInit(newInterfaceName),
        ),
        StringReplacement.prepend(
          before: "//DO-NOT-REMOVE REPOSITORIES_MOCK_FALLBACK_VALUE",
          text: templateRegisterFallback(newInterfaceName),
        ),
      ],
    );
  } catch (ex, stack) {
    print("EXCEPTION: $ex");
    print("stack: $stack");
    rethrow;
  }
}
