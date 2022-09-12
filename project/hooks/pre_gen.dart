/// {{activity_path}} - io/appflate/flutter_demo
import 'dart:io';

import "package:mason/mason.dart";
import 'package:recase/recase.dart';

Future<void> run(HookContext context) async {
  context.vars['activity_path'] =
      (context.vars['android_application_id'] as String).replaceAll('.', Platform.pathSeparator);
  context.vars['app_name_pascal'] = (context.vars['app_name'] as String).pascalCase;

  print("activity_path: ${context.vars['activity_path']}");
  print("app_name_pascal: ${context.vars['app_name_pascal']}");
}
