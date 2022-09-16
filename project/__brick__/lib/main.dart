// ignore_for_file: unused-code
import 'package:{{{app_package_name}}}/core/helpers.dart';
import 'package:{{{app_package_name}}}/dependency_injection/app_component.dart';
import 'package:{{{app_package_name}}}/{{{app_name_snake}}}_app.dart';

/// flag modified by unit tests so that app's code can adapt to unit tests
/// (i.e: disable animations in progress bars etc.)
bool isUnitTests = false;

void main() {
  configureDependencies();
  runApp(const {{{app_name_pascal}}}App());
}
