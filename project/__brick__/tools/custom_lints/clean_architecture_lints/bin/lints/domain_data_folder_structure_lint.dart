import 'package:analyzer/dart/analysis/results.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../utils/lint_codes.dart';
import '../utils/lint_utils.dart';

/// checks if domain entity class has only one public member (class,enum, mixin etc.)
class DomainDataFolderStructureLint extends PluginBase {
  @override
  Stream<Lint> getLints(ResolvedUnitResult unit) async* {
    final library = unit.libraryElement;
    if (!library.isDomainFile && !library.isDataFile) {
      return;
    }
    final removedPrefix =
        library.source.fullName.replaceAll(RegExp(r"^.*lib\/(?:features\/.+?(?=\/)|core)\/(?:domain|data)?"), "");
    if (removedPrefix == library.source.fullName) {
      print("NOT PREFIX: $removedPrefix");
      return;
    }
    if (RegExp(r".*\/(domain|data)\/.*").hasMatch(removedPrefix)) {
      yield Lint(
        code: LintCodes.missingCopyWithMethod,
        message:
            'domain and data folders can only be directly inside `lib/core/` or `lib/features/\$featureName/` and not nested any further down',
        location: unit.lintLocationFromLines(startLine: 1, endLine: 1),
        severity: LintSeverity.error,
        correction:
            "move the folder directly under the `lib/core` or `lib/features/\$featureName` without any subfolders inbetween",
      );
    }
  }
}
