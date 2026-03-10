import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_bloc/jaspr_bloc.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../helpers/client_mode.dart';

// ---------------------------------------------------------------------------
// Blocs
// ---------------------------------------------------------------------------

/// Manages a simple integer counter.
class CounterCubit extends Cubit<int> {
  CounterCubit() : super(0);

  /// Increments the counter by 1.
  void increment() => emit(state + 1);
}

/// Manages a list of log entries recording counter changes.
class LogCubit extends Cubit<List<String>> {
  LogCubit() : super(const []);

  /// Appends a new [entry] to the log.
  void addEntry(String entry) => emit([...state, entry]);

  /// Clears all log entries.
  void clear() => emit(const []);
}

/// Manages a separate score derived from the counter.
class ScoreCubit extends Cubit<int> {
  ScoreCubit() : super(0);

  /// Adds [points] to the score.
  void addPoints(int points) => emit(state + points);
}

// ---------------------------------------------------------------------------
// Components
// ---------------------------------------------------------------------------

/// A view that shows the counter and a log of all counter changes.
///
/// Uses [BlocListener] on [CounterCubit] to push entries into [LogCubit] so
/// the two blocs communicate through the presentation layer — neither cubit
/// has a direct reference to the other.
class _CounterWithLog extends StatelessComponent {
  const _CounterWithLog();

  @override
  Component build(BuildContext context) {
    return BlocListener<CounterCubit, int>(
      listener: (context, count) {
        context.read<LogCubit>().addEntry('count changed to $count');
      },
      child: div([
        BlocBuilder<CounterCubit, int>(
          builder: (context, count) {
            return p([Component.text('Count: $count')]);
          },
        ),
        BlocBuilder<LogCubit, List<String>>(
          builder: (context, log) {
            return div([
              Component.text('Log entries: ${log.length}'),
              ...log.map((e) => p([Component.text(e)])),
            ]);
          },
        ),
        button(onClick: () => context.read<CounterCubit>().increment(), [
          const Component.text('+'),
        ]),
      ]),
    );
  }
}

/// A view that shows two independent counters and a combined score.
///
/// Uses [BlocListener] on both counters to feed a shared [ScoreCubit],
/// demonstrating that multiple blocs can drive a single downstream bloc.
class _DualCounterWithScore extends StatelessComponent {
  const _DualCounterWithScore();

  @override
  Component build(BuildContext context) {
    return div([
      // Listen to counter A — each increment adds 1 point.
      BlocListener<_CounterACubit, int>(
        listener: (context, count) {
          context.read<ScoreCubit>().addPoints(1);
        },
        child: BlocBuilder<_CounterACubit, int>(
          builder: (context, count) {
            return p([Component.text('Counter A: $count')]);
          },
        ),
      ),
      // Listen to counter B — each increment adds 10 points.
      BlocListener<_CounterBCubit, int>(
        listener: (context, count) {
          context.read<ScoreCubit>().addPoints(10);
        },
        child: BlocBuilder<_CounterBCubit, int>(
          builder: (context, count) {
            return p([Component.text('Counter B: $count')]);
          },
        ),
      ),
      BlocBuilder<ScoreCubit, int>(
        builder: (context, score) {
          return p([Component.text('Score: $score')]);
        },
      ),
    ]);
  }
}

// ---------------------------------------------------------------------------
// Additional cubits needed for dual-counter scenario
// ---------------------------------------------------------------------------

/// Counter A for the dual-counter scenario.
class _CounterACubit extends Cubit<int> {
  _CounterACubit() : super(0);

  void increment() => emit(state + 1);
}

/// Counter B for the dual-counter scenario.
class _CounterBCubit extends Cubit<int> {
  _CounterBCubit() : super(0);

  void increment() => emit(state + 1);
}

// ---------------------------------------------------------------------------
// Integration tests
// ---------------------------------------------------------------------------

void main() {
  setUp(() => setIsClientForTesting(true));
  tearDown(() => resetIsClientForTesting());

  group('Multi-bloc integration', () {
    group('counter with log: BlocListener bridges two blocs', () {
      testComponents('initial render shows count 0 and empty log', (
        tester,
      ) async {
        tester.pumpComponent(
          MultiBlocProvider(
            providers: [
              BlocProvider<CounterCubit>(create: (_) => CounterCubit()),
              BlocProvider<LogCubit>(create: (_) => LogCubit()),
            ],
            child: const _CounterWithLog(),
          ),
        );

        expect(find.text('Count: 0'), findsOneComponent);
        expect(find.text('Log entries: 0'), findsOneComponent);
      });

      testComponents(
        'incrementing counter adds log entry via presentation layer',
        (tester) async {
          final counter = CounterCubit();
          final log = LogCubit();
          addTearDown(counter.close);
          addTearDown(log.close);

          tester.pumpComponent(
            MultiBlocProvider(
              providers: [
                BlocProvider<CounterCubit>.value(value: counter),
                BlocProvider<LogCubit>.value(value: log),
              ],
              child: const _CounterWithLog(),
            ),
          );

          counter.increment();
          await tester.pump();

          expect(find.text('Count: 1'), findsOneComponent);
          expect(find.text('Log entries: 1'), findsOneComponent);
          expect(find.text('count changed to 1'), findsOneComponent);
        },
      );

      testComponents('each increment produces a separate log entry', (
        tester,
      ) async {
        final counter = CounterCubit();
        final log = LogCubit();
        addTearDown(counter.close);
        addTearDown(log.close);

        tester.pumpComponent(
          MultiBlocProvider(
            providers: [
              BlocProvider<CounterCubit>.value(value: counter),
              BlocProvider<LogCubit>.value(value: log),
            ],
            child: const _CounterWithLog(),
          ),
        );

        counter.increment();
        await tester.pump();
        counter.increment();
        await tester.pump();
        counter.increment();
        await tester.pump();

        expect(find.text('Count: 3'), findsOneComponent);
        expect(find.text('Log entries: 3'), findsOneComponent);
        expect(find.text('count changed to 1'), findsOneComponent);
        expect(find.text('count changed to 2'), findsOneComponent);
        expect(find.text('count changed to 3'), findsOneComponent);
      });

      testComponents('counter and log blocs update their views independently', (
        tester,
      ) async {
        final counter = CounterCubit();
        final log = LogCubit();
        addTearDown(counter.close);
        addTearDown(log.close);

        tester.pumpComponent(
          MultiBlocProvider(
            providers: [
              BlocProvider<CounterCubit>.value(value: counter),
              BlocProvider<LogCubit>.value(value: log),
            ],
            child: const _CounterWithLog(),
          ),
        );

        // Manually add a log entry without incrementing the counter.
        log.addEntry('manual entry');
        await tester.pump();

        // Counter stays at 0 but log shows 1 entry.
        expect(find.text('Count: 0'), findsOneComponent);
        expect(find.text('Log entries: 1'), findsOneComponent);
        expect(find.text('manual entry'), findsOneComponent);
      });
    });

    group('dual-counter with score: multiple blocs drive a shared bloc', () {
      testComponents('initial render shows both counters and score at zero', (
        tester,
      ) async {
        tester.pumpComponent(
          MultiBlocProvider(
            providers: [
              BlocProvider<_CounterACubit>(create: (_) => _CounterACubit()),
              BlocProvider<_CounterBCubit>(create: (_) => _CounterBCubit()),
              BlocProvider<ScoreCubit>(create: (_) => ScoreCubit()),
            ],
            child: const _DualCounterWithScore(),
          ),
        );

        expect(find.text('Counter A: 0'), findsOneComponent);
        expect(find.text('Counter B: 0'), findsOneComponent);
        expect(find.text('Score: 0'), findsOneComponent);
      });

      testComponents('incrementing counter A adds 1 point to the score', (
        tester,
      ) async {
        final counterA = _CounterACubit();
        final counterB = _CounterBCubit();
        final score = ScoreCubit();
        addTearDown(counterA.close);
        addTearDown(counterB.close);
        addTearDown(score.close);

        tester.pumpComponent(
          MultiBlocProvider(
            providers: [
              BlocProvider<_CounterACubit>.value(value: counterA),
              BlocProvider<_CounterBCubit>.value(value: counterB),
              BlocProvider<ScoreCubit>.value(value: score),
            ],
            child: const _DualCounterWithScore(),
          ),
        );

        counterA.increment();
        await tester.pump();

        expect(find.text('Counter A: 1'), findsOneComponent);
        expect(find.text('Score: 1'), findsOneComponent);
      });

      testComponents('incrementing counter B adds 10 points to the score', (
        tester,
      ) async {
        final counterA = _CounterACubit();
        final counterB = _CounterBCubit();
        final score = ScoreCubit();
        addTearDown(counterA.close);
        addTearDown(counterB.close);
        addTearDown(score.close);

        tester.pumpComponent(
          MultiBlocProvider(
            providers: [
              BlocProvider<_CounterACubit>.value(value: counterA),
              BlocProvider<_CounterBCubit>.value(value: counterB),
              BlocProvider<ScoreCubit>.value(value: score),
            ],
            child: const _DualCounterWithScore(),
          ),
        );

        counterB.increment();
        await tester.pump();

        expect(find.text('Counter B: 1'), findsOneComponent);
        expect(find.text('Score: 10'), findsOneComponent);
      });

      testComponents('increments from both counters accumulate in the score', (
        tester,
      ) async {
        final counterA = _CounterACubit();
        final counterB = _CounterBCubit();
        final score = ScoreCubit();
        addTearDown(counterA.close);
        addTearDown(counterB.close);
        addTearDown(score.close);

        tester.pumpComponent(
          MultiBlocProvider(
            providers: [
              BlocProvider<_CounterACubit>.value(value: counterA),
              BlocProvider<_CounterBCubit>.value(value: counterB),
              BlocProvider<ScoreCubit>.value(value: score),
            ],
            child: const _DualCounterWithScore(),
          ),
        );

        // A: +1 point each, B: +10 points each.
        counterA.increment(); // score 1
        await tester.pump();
        counterB.increment(); // score 11
        await tester.pump();
        counterA.increment(); // score 12
        await tester.pump();

        expect(find.text('Counter A: 2'), findsOneComponent);
        expect(find.text('Counter B: 1'), findsOneComponent);
        expect(find.text('Score: 12'), findsOneComponent);
      });

      testComponents('each bloc renders its own view independently', (
        tester,
      ) async {
        final counterA = _CounterACubit();
        final counterB = _CounterBCubit();
        final score = ScoreCubit();
        addTearDown(counterA.close);
        addTearDown(counterB.close);
        addTearDown(score.close);

        tester.pumpComponent(
          MultiBlocProvider(
            providers: [
              BlocProvider<_CounterACubit>.value(value: counterA),
              BlocProvider<_CounterBCubit>.value(value: counterB),
              BlocProvider<ScoreCubit>.value(value: score),
            ],
            child: const _DualCounterWithScore(),
          ),
        );

        // Only increment counter A — counter B and score text must update correctly.
        counterA.increment();
        await tester.pump();

        expect(find.text('Counter A: 1'), findsOneComponent);
        expect(find.text('Counter B: 0'), findsOneComponent);
        expect(find.text('Score: 1'), findsOneComponent);
      });
    });
  });
}
