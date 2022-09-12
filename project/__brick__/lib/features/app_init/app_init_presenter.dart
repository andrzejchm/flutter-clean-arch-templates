import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:{{{app_package_name}}}/core/domain/model/user.dart';
import 'package:{{{app_package_name}}}/core/domain/stores/user_store.dart';
import 'package:{{{app_package_name}}}/core/domain/use_cases/app_init_use_case.dart';
import 'package:{{{app_package_name}}}/core/helpers.dart';
import 'package:{{{app_package_name}}}/core/utils/bloc_extensions.dart';
import 'package:{{{app_package_name}}}/core/utils/either_extensions.dart';
import 'package:{{{app_package_name}}}/core/utils/mvp_extensions.dart';
import 'package:{{{app_package_name}}}/features/app_init/app_init_navigator.dart';
import 'package:{{{app_package_name}}}/features/app_init/app_init_presentation_model.dart';

class AppInitPresenter extends Cubit<AppInitViewModel> with CubitToCubitCommunicationMixin<AppInitViewModel> {
  AppInitPresenter(
    AppInitPresentationModel super.model,
    this.navigator,
    this.appInitUseCase,
    this.userStore,
  ) {
    listenTo<User>(
      userStore,
      onChange: (user) => emit(_model.copyWith(user: user)),
    );
  }

  final AppInitNavigator navigator;
  final AppInitUseCase appInitUseCase;
  final UserStore userStore;

  AppInitPresentationModel get _model => state as AppInitPresentationModel;

  Future<void> onInit() async {
    await appInitUseCase
        .execute() //
        .observeStatusChanges((result) => emit(_model.copyWith(appInitResult: result)))
        .asyncFold(
          (fail) => navigator.showError(fail.displayableFailure()),
          (success) => doNothing(), //todo!
        );
  }
}
