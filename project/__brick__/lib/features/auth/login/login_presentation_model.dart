import 'package:{{{app_package_name}}}/features/auth/login/login_initial_params.dart';

/// Model used by presenter, contains fields that are relevant to presenters and implements ViewModel to expose data to view (page)
class LoginPresentationModel implements LoginViewModel {
  /// Creates the initial state
  LoginPresentationModel.initial(
    // ignore: avoid_unused_constructor_parameters
    LoginInitialParams initialParams,
  );

  /// Used for the copyWith method
  LoginPresentationModel._();

  LoginPresentationModel copyWith() {
    return LoginPresentationModel._();
  }
}

/// Interface to expose fields used by the view (page).
abstract class LoginViewModel {}
