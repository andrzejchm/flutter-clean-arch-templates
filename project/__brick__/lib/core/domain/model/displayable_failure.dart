import 'package:{{{app_package_name}}}/localization/app_localizations_utils.dart';

/// A failure with the title and message that could be easly displayed as a dialog or snackbar
class DisplayableFailure {
  DisplayableFailure(
    this.cause, {
    required this.title,
    required this.message,
  });

  DisplayableFailure.commonError(this.cause, [String? message])
      : title = appLocalizations.commonErrorTitle,
        // TODO move this to strings file
        message = message ?? appLocalizations.commonErrorMessage;

  dynamic cause;
  String title;
  String message;

  @override
  String toString() {
    return 'DisplayableFailure{cause: $cause, title: $title, message: $message}';
  }
}

abstract class HasDisplayableFailure {
  DisplayableFailure displayableFailure();
}
