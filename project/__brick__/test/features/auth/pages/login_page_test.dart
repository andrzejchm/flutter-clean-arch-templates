import 'package:flutter_test/flutter_test.dart';

import 'package:{{{app_package_name}}}/dependency_injection/app_component.dart';
import 'package:{{{app_package_name}}}/features/auth/login/login_initial_params.dart';
import 'package:{{{app_package_name}}}/features/auth/login/login_navigator.dart';
import 'package:{{{app_package_name}}}/features/auth/login/login_page.dart';
import 'package:{{{app_package_name}}}/features/auth/login/login_presentation_model.dart';
import 'package:{{{app_package_name}}}/features/auth/login/login_presenter.dart';
import '../../../mocks/mocks.dart';
import '../../../test_utils/golden_tests_utils.dart';

Future<void> main() async {
  late LoginPage page;
  late LoginInitialParams initParams;
  late LoginPresentationModel model;
  late LoginPresenter presenter;
  late LoginNavigator navigator;

  void initMvp() {
    initParams = const LoginInitialParams();
    model = LoginPresentationModel.initial(
      initParams,
    );
    navigator = LoginNavigator(Mocks.appNavigator);
    presenter = LoginPresenter(
      model,
      navigator,
    );
    page = LoginPage(presenter: presenter);
  }

  await screenshotTest(
    'login_page',
    setUp: () async {
      initMvp();
    },
    pageBuilder: () => page,
  );

  test('getIt page resolves successfully', () async {
    initMvp();
    final page = getIt<LoginPage>(param1: initParams);
    expect(page.presenter, isNotNull);
    expect(page, isNotNull);
  });
}
