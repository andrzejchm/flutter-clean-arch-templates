// ignore_for_file: unused-code, unused-files
import 'package:flutter/material.dart';
import 'package:{{{app_package_name}}}/core/utils/logging.dart';
import 'package:{{{app_package_name}}}/navigation/app_navigator.dart';

/// does... nothing ;)
T? doNothing<T>() {
  return null;
}

/// shows dialog with "not implemented" message. its var so that it can be replaced for tests
void Function({BuildContext? context, String? message}) notImplemented = ({String? message, BuildContext? context}) {
  logError(UnimplementedError('not implemented${message == null ? '' : ':\n$message'}'), StackTrace.current);
  showDialog(
    context: context ?? AppNavigator.navigatorKey.currentContext!,
    builder: (context) => AlertDialog(
      title: const Text('Not implemented'),
      content: Text(message ?? "This feature is not yet implemented"),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('OK'),
        ),
      ],
    ),
  );
};

/// method that allows suppressing the `unused-code` metric
/// https://github.com/dart-code-checker/dart-code-metrics/pull/929
void suppressUnusedCodeWarning(dynamic anything) => doNothing();
