import 'package:bloc/bloc.dart';

/// A simple counter cubit that manages an integer count.
///
/// This cubit depends only on the `bloc` package and contains
/// zero Flutter- or Jaspr-specific code. It can therefore be
/// imported unchanged in a Flutter app (via `flutter_bloc`) and
/// in a Jaspr web app (via `jaspr_bloc`), demonstrating true
/// cross-platform business-logic sharing.
///
/// Example:
/// ```dart
/// final cubit = CounterCubit();
/// cubit.increment(); // state == 1
/// cubit.decrement(); // state == 0
/// ```
class CounterCubit extends Cubit<int> {
  /// Creates a [CounterCubit] with an initial count of 0.
  CounterCubit() : super(0);

  /// Increments the counter by 1.
  void increment() => emit(state + 1);

  /// Decrements the counter by 1.
  void decrement() => emit(state - 1);
}
