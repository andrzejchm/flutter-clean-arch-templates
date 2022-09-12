import 'package:{{{app_package_name}}}/navigation/app_navigator.dart';
import 'package:{{{app_package_name}}}/navigation/error_dialog_route.dart';
import 'package:{{{app_package_name}}}/navigation/no_routes.dart';

class AppInitNavigator with NoRoutes, ErrorDialogRoute {
  AppInitNavigator(this.appNavigator);

  @override
  final AppNavigator appNavigator;
}
