import 'package:flutter_test/flutter_test.dart';

import 'package:{{{app_package_name}}}/features/auth/login/login_initial_params.dart';
import 'package:{{{app_package_name}}}/features/auth/login/login_presentation_model.dart';
import 'package:{{{app_package_name}}}/features/auth/login/login_presenter.dart';
import '../mocks/auth_mock_definitions.dart';

void main() {
  late LoginPresentationModel model;
  late LoginPresenter presenter;
  late MockLoginNavigator navigator;

  test(
    'sample test',
    () {
      expect(presenter, isNotNull); // TODO implement this
    },
  );

  setUp(() {
    model = LoginPresentationModel.initial(const LoginInitialParams());
    navigator = MockLoginNavigator();
    presenter = LoginPresenter(
      model,
      navigator,
    );
  });
}
