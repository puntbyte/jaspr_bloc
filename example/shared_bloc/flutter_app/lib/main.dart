import 'package:common_blocs/common_blocs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Entry point for the Flutter shared-bloc example app.
void main() {
  runApp(const App());
}

/// Root application widget.
class App extends StatelessWidget {
  /// Creates an [App].
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shared Bloc Counter — Flutter',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: BlocProvider<CounterCubit>(
        create: (_) => CounterCubit(),
        child: const CounterPage(),
      ),
    );
  }
}

/// Counter page that reads [CounterCubit] from the widget tree.
///
/// Imports [CounterCubit] from the shared `common_blocs` package —
/// the same cubit used by the Jaspr app without any modification.
class CounterPage extends StatelessWidget {
  /// Creates a [CounterPage].
  const CounterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Shared Bloc Counter — Flutter')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'CounterCubit is imported from the shared common_blocs package.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            // BlocBuilder rebuilds the count text on every state change.
            BlocBuilder<CounterCubit, int>(
              builder: (context, count) {
                return Text(
                  'Count: $count',
                  style: Theme.of(context).textTheme.headlineMedium,
                );
              },
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () => context.read<CounterCubit>().increment(),
                  child: const Text('+'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () => context.read<CounterCubit>().decrement(),
                  child: const Text('-'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
