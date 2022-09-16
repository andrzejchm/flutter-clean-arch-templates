// ignore_for_file: unused-code, unused-files
import 'package:flutter/material.dart';
import 'package:{{{app_package_name}}}/localization/app_localizations_utils.dart';
import 'package:{{{app_package_name}}}/navigation/app_navigator.dart';

mixin AlertDialogRoute {
  Future<void> showAlert({
    required String title,
    required String message,
  }) {
    return showDialog(
      context: AppNavigator.navigatorKey.currentContext!,
      builder: (context) => _AlertDialog(
        title: title,
        message: message,
      ),
    );
  }
}

class _AlertDialog extends StatelessWidget {
  const _AlertDialog({
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(appLocalizations.okAction),
        ),
      ],
    );
  }
}
