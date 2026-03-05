import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_bloc/jaspr_bloc.dart';

import 'counter_cubit.dart';

/// The interactive counter page.
///
/// Marked [@client] so it is hydrated in the browser and becomes
/// interactive. All bloc wiring lives inside this component tree
/// so that [BlocProvider] and [BlocBuilder] work correctly after
/// client hydration.
@client
class CounterPage extends StatelessComponent {
  const CounterPage({super.key});

  @override
  Component build(BuildContext context) {
    // BlocProvider creates and manages the CounterCubit lifecycle.
    // Placing it inside the @client tree ensures reactive stream
    // subscriptions are activated after browser hydration.
    return BlocProvider<CounterCubit>(
      create: (_) => CounterCubit(),
      child: const _CounterView(),
    );
  }
}

/// Renders the counter display and action buttons.
///
/// Uses [BlocBuilder] to rebuild the count label on each state change
/// and [BuildContext.read] in button handlers to dispatch cubit calls
/// without subscribing to updates.
class _CounterView extends StatelessComponent {
  const _CounterView();

  @override
  Component build(BuildContext context) {
    return div([
      const h1([Component.text('Jaspr Bloc Counter')]),
      // BlocBuilder subscribes to CounterCubit and rebuilds the
      // count paragraph whenever the state changes.
      BlocBuilder<CounterCubit, int>(
        builder: (context, count) {
          return p([Component.text('Count: $count')]);
        },
      ),
      // context.read retrieves the cubit without subscribing — safe
      // to call in event handlers.
      div([
        button(onClick: () => context.read<CounterCubit>().increment(), [
          const Component.text('+'),
        ]),
        button(onClick: () => context.read<CounterCubit>().decrement(), [
          const Component.text('-'),
        ]),
      ]),
    ]);
  }
}
