// ignore_for_file: unused-code
import 'dart:async';
import 'dart:ui';

import 'package:{{{app_package_name}}}/core/utils/logging.dart';
import 'package:{{{app_package_name}}}/dependency_injection/app_component.dart';
import 'package:{{{app_package_name}}}/{{{app_name_snake}}}_app.dart';
import 'package:flutter/material.dart';

/// flag modified by unit tests so that app's code can adapt to unit tests
/// (i.e: disable animations in progress bars etc.)
bool isUnitTests = false;

void main() {
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    logError(details.exception, details.stack);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    logError(error, stack);
    return false;
  };
  runZonedGuarded(() {
    configureDependencies();
    runApp(const {{{app_name_pascal}}}App());
  },
        (error, stack) => logError(error, stack),
  );
}
