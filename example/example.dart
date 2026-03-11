/// Basic usage example for jaspr_bloc.
///
/// Demonstrates the core API: creating a Cubit, wrapping a component tree
/// with [BlocProvider], and reading state via [BlocBuilder] and
/// [BuildContext.watch].
///
/// See the `counter/` and `shared_bloc/` subdirectories for full runnable
/// Jaspr application examples.
library;

import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_bloc/jaspr_bloc.dart';

// ---------------------------------------------------------------------------
// 1. Define a Cubit — identical to flutter_bloc usage.
// ---------------------------------------------------------------------------

/// A simple counter cubit that holds an [int] state.
class CounterCubit extends Cubit<int> {
  /// Creates a [CounterCubit] with an initial count of zero.
  CounterCubit() : super(0);

  /// Increments the counter by one.
  void increment() => emit(state + 1);

  /// Decrements the counter by one.
  void decrement() => emit(state - 1);
}

// ---------------------------------------------------------------------------
// 2. Provide the cubit to the component tree with BlocProvider.
// ---------------------------------------------------------------------------

/// Root component that provides [CounterCubit] to its subtree.
class CounterApp extends StatelessComponent {
  /// Creates a [CounterApp].
  const CounterApp({super.key});

  @override
  Component build(BuildContext context) {
    return BlocProvider(
      create: (_) => CounterCubit(),
      child: const CounterView(),
    );
  }
}

// ---------------------------------------------------------------------------
// 3. Consume state with BlocBuilder — rebuilds on every new state.
// ---------------------------------------------------------------------------

/// Displays the current counter value and increment/decrement buttons.
class CounterView extends StatelessComponent {
  /// Creates a [CounterView].
  const CounterView({super.key});

  @override
  Component build(BuildContext context) {
    return div([
      BlocBuilder<CounterCubit, int>(
        builder: (context, count) {
          return p([Component.text('Count: $count')]);
        },
      ),
      button(onClick: () => context.read<CounterCubit>().increment(), [
        const Component.text('+'),
      ]),
      button(onClick: () => context.read<CounterCubit>().decrement(), [
        const Component.text('-'),
      ]),
    ]);
  }
}
