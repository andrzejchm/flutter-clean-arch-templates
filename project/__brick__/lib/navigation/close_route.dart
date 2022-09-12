// ignore_for_file: unused-code, unused-files
import 'package:{{{app_package_name}}}/navigation/app_navigator.dart';

mixin CloseRoute<T> {
  AppNavigator get appNavigator;

  void close() => appNavigator.close();
}
