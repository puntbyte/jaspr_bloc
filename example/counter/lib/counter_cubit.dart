import 'package:bloc/bloc.dart';

/// A simple counter cubit that manages an integer count.
///
/// This same file can be used unchanged in a Flutter app
/// (via flutter_bloc) or a Jaspr app (via jaspr_bloc), demonstrating
/// the cross-platform code sharing that jaspr_bloc enables.
class CounterCubit extends Cubit<int> {
  CounterCubit() : super(0);

  /// Increments the counter by 1.
  void increment() => emit(state + 1);

  /// Decrements the counter by 1.
  void decrement() => emit(state - 1);
}
