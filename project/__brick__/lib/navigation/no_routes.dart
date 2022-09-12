import 'package:{{{app_package_name}}}/navigation/app_navigator.dart';

/// used with navigators that don't have any routes (yet).
mixin NoRoutes {
  AppNavigator get appNavigator;
}
