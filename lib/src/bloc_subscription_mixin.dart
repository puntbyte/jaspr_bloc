import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:jaspr/jaspr.dart';

import 'jaspr_bloc_config.dart';

/// Legacy internal subscription helper retained for deep-import compatibility.
///
/// It is no longer exported by `package:jaspr_bloc/jaspr_bloc.dart`, matching
/// flutter_bloc's public export surface.
mixin BlocSubscriptionMixin<T extends StatefulComponent> on State<T> {
  StreamSubscription<dynamic>? _subscription;

  /// Cancels the previous subscription and subscribes to [bloc].
  void subscribeTo<B extends StateStreamable<S>, S>(
    B bloc, {
    required void Function(S state) onState,
    bool Function(S previous, S current)? filter,
  }) {
    unsubscribe();
    if (!isClientEnvironment) return;

    var previous = bloc.state;
    _subscription = bloc.stream.listen((state) {
      if (filter?.call(previous, state) ?? true) onState(state);
      previous = state;
    });
  }

  /// Cancels the active subscription.
  void unsubscribe() {
    unawaited(_subscription?.cancel() ?? Future<void>.value());
    _subscription = null;
  }

  @override
  void dispose() {
    unsubscribe();
    super.dispose();
  }
}
