// ignore_for_file: cancel_subscriptions
import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

//ignore:prefer-match-file-name
mixin PresenterStateMixin<M, P extends Cubit<M>, T extends HasPresenter<P>> on State<T> {
  P get presenter => widget.presenter;

  M get state => presenter.state;

  Widget stateObserver({
    required BlocWidgetBuilder<M> builder,
    BlocBuilderCondition<M>? buildWhen,
  }) {
    return BlocBuilder<P, M>(
      bloc: presenter,
      buildWhen: buildWhen,
      builder: builder,
    );
  }

  @override
  void dispose() {
    super.dispose();
    presenter.close();
  }
}

mixin HasPresenter<P> on StatefulWidget {
  P get presenter;
}

mixin SubscriptionsMixin<T> on Cubit<T> {
  final _subscriptions = <String, StreamSubscription<dynamic>>{};

  /// To avoid start listening the same stream twice we have to provide unique [subscriptionId]
  void listenTo<C>({
    required Stream<C> stream,
    required String subscriptionId,
    required void Function(C) onChange,
  }) {
    if (!_subscriptions.containsKey(subscriptionId)) {
      final subscription = stream.listen(onChange);
      addSubscription(subscription: subscription, subscriptionId: subscriptionId);
    }
  }

  void addSubscription({required StreamSubscription<dynamic> subscription, required String subscriptionId}) {
    _subscriptions.putIfAbsent(subscriptionId, () => subscription);
  }

  ///Cancel and close single subscriptions
  Future<void> closeSubscription(String subscriptionId) async {
    final subscription = _subscriptions[subscriptionId];
    if (subscription != null) {
      await subscription.cancel();
      _subscriptions.remove(subscriptionId);
    }
  }

  ///Cancel and close all subscriptions
  @override
  Future<void> close() async {
    await Future.wait(_subscriptions.values.map((it) => it.cancel()));
    await super.close();
    _subscriptions.clear();
  }
}

