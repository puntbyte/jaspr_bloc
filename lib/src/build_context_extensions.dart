import 'package:bloc/bloc.dart';
import 'package:jaspr/jaspr.dart';

import 'bloc_provider.dart';

/// Extensions on [BuildContext] for ergonomic bloc access.
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
}
