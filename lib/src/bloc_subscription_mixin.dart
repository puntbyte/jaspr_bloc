import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:jaspr/jaspr.dart';

import 'jaspr_bloc_config.dart';

/// A mixin for [State] that manages a single [StreamSubscription] to a [StateStreamable].
///
/// This mixin provides lifecycle management for stream subscriptions in Jaspr
/// components, automatically canceling the subscription when the component is
/// disposed.
///
/// Usage:
/// ```dart
/// class MyComponent extends StatefulComponent {
///   @override
///   State<MyComponent> createState() => _MyComponentState();
/// }
///
/// class _MyComponentState extends State<MyComponent>
///     with BlocSubscriptionMixin {
///   @override
///   void initState() {
///     super.initState();
///     final bloc = BlocProvider.of<MyBloc>(context);
///     subscribeTo(
///       bloc,
///       onState: (state) {
///         setState(() {});
///       },
///       filter: (previous, current) => previous != current,
///     );
///   }
///
///   @override
///   Component build(BuildContext context) {
///     return div([]);
///   }
/// }
/// ```
mixin BlocSubscriptionMixin<T extends StatefulComponent> on State<T> {
  StreamSubscription<dynamic>? _subscription;

  /// Subscribes to a [StateStreamable] and calls [onState] for each new state.
  ///
  /// The [bloc] parameter is the state streamable to subscribe to.
  ///
  /// The [onState] callback is invoked for each new state emitted by the bloc.
  ///
  /// The optional [filter] predicate can be used to prevent [onState] from
  /// being called. If [filter] returns false, [onState] will not be called
  /// for that state change.
  ///
  /// The subscription is automatically canceled when the component is disposed.
  void subscribeTo<B extends StateStreamable<S>, S>(
    B bloc, {
    required void Function(S state) onState,
    bool Function(S previous, S current)? filter,
  }) {
    if (!isClientEnvironment) {
      return;
    }
    S previous = bloc.state;
    _subscription = bloc.stream.listen((state) {
      if (filter == null || filter(previous, state)) {
        onState(state);
      }
      previous = state;
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
