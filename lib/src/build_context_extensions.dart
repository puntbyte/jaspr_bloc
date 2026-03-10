import 'package:bloc/bloc.dart';
import 'package:jaspr/jaspr.dart';

import 'bloc_inherited.dart';
import 'bloc_provider.dart';

/// Extensions on `BuildContext` for ergonomic bloc access.
///
/// These extensions mirror the API provided by `flutter_bloc`, enabling
/// familiar patterns for developers working across Flutter and Jaspr.
extension JasprBlocContextExtensions on BuildContext {
  /// Retrieves the nearest [BlocProvider<T>] ancestor's bloc.
  ///
  /// Does not subscribe to changes. The calling component will not rebuild
  /// when the bloc instance provided by [BlocProvider] changes.
  ///
  /// Equivalent to [BlocProvider.of<T>]:
  ///
  /// ```dart
  /// // Both are equivalent:
  /// final cubit = context.read<CounterCubit>();
  /// final cubit = BlocProvider.of<CounterCubit>(context);
  /// ```
  ///
  /// Throws an [AssertionError] if no [BlocProvider<T>] is found in the
  /// ancestor tree.
  T read<T extends BlocBase<Object?>>() {
    return BlocProvider.of<T>(this);
  }

  /// Retrieves the nearest [BlocProvider<T>] ancestor's bloc and subscribes
  /// to rebuild notifications.
  ///
  /// The calling component will rebuild whenever the bloc's state changes.
  /// Use this inside a `build` method to reactively consume state.
  ///
  /// ```dart
  /// @override
  /// Component build(BuildContext context) {
  ///   final cubit = context.watch<CounterCubit>();
  ///   return span([Component.text('${cubit.state}')]);
  /// }
  /// ```
  ///
  /// For side-effect-only access that does not require rebuilds, prefer
  /// [read]. For rebuild filtering based on a derived value, prefer
  /// [BlocSelector] or [select].
  ///
  /// Throws an [AssertionError] if no [BlocProvider<T>] is found in the
  /// ancestor tree.
  T watch<T extends BlocBase<Object?>>() {
    return BlocInherited.of<T>(this);
  }

  /// Looks up the nearest [BlocProvider<T>] and returns a value derived from
  /// the bloc's current state via [selector].
  ///
  /// The calling component subscribes to the bloc and rebuilds whenever the
  /// bloc emits a new state. The [selector] is re-evaluated on each rebuild
  /// and the returned value [R] is provided to the caller.
  ///
  /// ```dart
  /// @override
  /// Component build(BuildContext context) {
  ///   final name = context.select<UserCubit, UserState, String>(
  ///     (state) => state.name,
  ///   );
  ///   return span([Component.text('Hello, $name')]);
  /// }
  /// ```
  ///
  /// Note: the calling component rebuilds on every state emission, not only
  /// when the selected value [R] changes. For strict rebuild gating based on
  /// the selected value, use [BlocSelector] instead.
  ///
  /// Throws an [AssertionError] if no [BlocProvider<T>] is found in the
  /// ancestor tree.
  R select<T extends BlocBase<S>, S, R>(R Function(S state) selector) {
    final T bloc = BlocInherited.of<T>(this);
    return selector(bloc.state);
  }
}
