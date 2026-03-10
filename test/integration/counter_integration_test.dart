import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_bloc/jaspr_bloc.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../helpers/client_mode.dart';

// ---------------------------------------------------------------------------
// Counter cubit — mirrors the example/counter cubit exactly.
// ---------------------------------------------------------------------------

/// A simple counter cubit that manages an integer count.
///
/// Mirrors the counter example app cubit to verify the full component stack
/// works end-to-end in a test environment.
class CounterCubit extends Cubit<int> {
  CounterCubit() : super(0);

  /// Increments the counter by 1.
  void increment() => emit(state + 1);

  /// Decrements the counter by 1.
  void decrement() => emit(state - 1);
}

// ---------------------------------------------------------------------------
// Counter view — mirrors the structure of the example counter page.
// ---------------------------------------------------------------------------

/// Renders the counter display and action buttons.
///
/// Structurally equivalent to the counter example's [_CounterView] — the
/// [BlocProvider] is provided externally so the test can supply its own cubit.
class _CounterView extends StatelessComponent {
  const _CounterView();

  @override
  Component build(BuildContext context) {
    return div([
      const h1([Component.text('Counter Integration Test')]),
      BlocBuilder<CounterCubit, int>(
        builder: (context, count) {
          return p([Component.text('Count: $count')]);
        },
      ),
      div([
        button(
          id: 'increment',
          onClick: () => context.read<CounterCubit>().increment(),
          [const Component.text('+')],
        ),
        button(
          id: 'decrement',
          onClick: () => context.read<CounterCubit>().decrement(),
          [const Component.text('-')],
        ),
      ]),
    ]);
  }
}

// ---------------------------------------------------------------------------
// Integration tests
// ---------------------------------------------------------------------------

void main() {
  setUp(() => setIsClientForTesting(true));
  tearDown(() => resetIsClientForTesting());

  group('Counter integration', () {
    group('initial render', () {
      testComponents('renders initial count of zero', (tester) async {
        tester.pumpComponent(
          BlocProvider<CounterCubit>(
            create: (_) => CounterCubit(),
            child: const _CounterView(),
          ),
        );

        expect(find.text('Count: 0'), findsOneComponent);
      });

      testComponents('renders the counter heading', (tester) async {
        tester.pumpComponent(
          BlocProvider<CounterCubit>(
            create: (_) => CounterCubit(),
            child: const _CounterView(),
          ),
        );

        expect(find.text('Counter Integration Test'), findsOneComponent);
      });

      testComponents('renders increment and decrement buttons', (tester) async {
        tester.pumpComponent(
          BlocProvider<CounterCubit>(
            create: (_) => CounterCubit(),
            child: const _CounterView(),
          ),
        );

        expect(find.text('+'), findsOneComponent);
        expect(find.text('-'), findsOneComponent);
      });
    });

    group('increment interactions', () {
      testComponents('count increments when increment is called once', (
        tester,
      ) async {
        final cubit = CounterCubit();
        addTearDown(cubit.close);

        tester.pumpComponent(
          BlocProvider<CounterCubit>.value(
            value: cubit,
            child: const _CounterView(),
          ),
        );

        expect(find.text('Count: 0'), findsOneComponent);

        // Simulate user clicking the '+' button.
        cubit.increment();
        await tester.pump();

        expect(find.text('Count: 1'), findsOneComponent);
        expect(find.text('Count: 0'), findsNothing);
      });

      testComponents(
        'count increments correctly after multiple button presses',
        (tester) async {
          final cubit = CounterCubit();
          addTearDown(cubit.close);

          tester.pumpComponent(
            BlocProvider<CounterCubit>.value(
              value: cubit,
              child: const _CounterView(),
            ),
          );

          cubit.increment();
          await tester.pump();
          expect(find.text('Count: 1'), findsOneComponent);

          cubit.increment();
          await tester.pump();
          expect(find.text('Count: 2'), findsOneComponent);

          cubit.increment();
          await tester.pump();
          expect(find.text('Count: 3'), findsOneComponent);
        },
      );
    });

    group('decrement interactions', () {
      testComponents('count decrements when decrement is called', (
        tester,
      ) async {
        final cubit = CounterCubit();
        addTearDown(cubit.close);

        tester.pumpComponent(
          BlocProvider<CounterCubit>.value(
            value: cubit,
            child: const _CounterView(),
          ),
        );

        // First increment so decrement produces 0, not negative.
        cubit.increment();
        await tester.pump();
        expect(find.text('Count: 1'), findsOneComponent);

        cubit.decrement();
        await tester.pump();
        expect(find.text('Count: 0'), findsOneComponent);
      });

      testComponents('count can go below zero on decrement', (tester) async {
        final cubit = CounterCubit();
        addTearDown(cubit.close);

        tester.pumpComponent(
          BlocProvider<CounterCubit>.value(
            value: cubit,
            child: const _CounterView(),
          ),
        );

        cubit.decrement();
        await tester.pump();
        expect(find.text('Count: -1'), findsOneComponent);
      });
    });

    group('mixed interactions', () {
      testComponents(
        'alternating increment and decrement updates the display correctly',
        (tester) async {
          final cubit = CounterCubit();
          addTearDown(cubit.close);

          tester.pumpComponent(
            BlocProvider<CounterCubit>.value(
              value: cubit,
              child: const _CounterView(),
            ),
          );

          cubit.increment();
          await tester.pump();
          expect(find.text('Count: 1'), findsOneComponent);

          cubit.increment();
          await tester.pump();
          expect(find.text('Count: 2'), findsOneComponent);

          cubit.decrement();
          await tester.pump();
          expect(find.text('Count: 1'), findsOneComponent);

          cubit.increment();
          await tester.pump();
          expect(find.text('Count: 2'), findsOneComponent);
        },
      );
    });

    group('state change renders correct count text', () {
      testComponents(
        'only the updated count label is visible after increment',
        (tester) async {
          final cubit = CounterCubit();
          addTearDown(cubit.close);

          tester.pumpComponent(
            BlocProvider<CounterCubit>.value(
              value: cubit,
              child: const _CounterView(),
            ),
          );

          cubit.increment();
          await tester.pump();

          expect(find.text('Count: 1'), findsOneComponent);
          expect(find.text('Count: 0'), findsNothing);
        },
      );
    });
  });
}
