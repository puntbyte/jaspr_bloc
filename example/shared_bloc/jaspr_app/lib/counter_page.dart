import 'package:common_blocs/common_blocs.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_bloc/jaspr_bloc.dart';

/// The interactive counter page, hydrated in the browser.
///
/// Imports [CounterCubit] from the shared `common_blocs` package —
/// the same cubit used by the Flutter app without any modification.
///
/// Annotated [@client] so Jaspr hydrates this component in the
/// browser after the server renders the initial HTML.
@client
class CounterPage extends StatelessComponent {
  /// Creates a [CounterPage].
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
/// Uses [BlocBuilder] to rebuild the count label on each state change.
class _CounterView extends StatelessComponent {
  const _CounterView();

  @override
  Component build(BuildContext context) {
    return div([
      const h1([Component.text('Shared Bloc Counter — Jaspr')]),
      const p([
        Component.text(
          'CounterCubit is imported from the shared common_blocs package.',
        ),
      ]),
      BlocBuilder<CounterCubit, int>(
        builder: (context, count) {
          return p([Component.text('Count: $count')]);
        },
      ),
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
