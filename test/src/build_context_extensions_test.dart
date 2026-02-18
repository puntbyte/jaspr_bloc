import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_bloc/jaspr_bloc.dart';
import 'package:jaspr_test/jaspr_test.dart';

// ---------------------------------------------------------------------------
// Test doubles
// ---------------------------------------------------------------------------

/// A simple integer-emitting cubit used across multiple test groups.
class CounterCubit extends Cubit<int> {
  CounterCubit([super.initialState = 0]);

  void increment() => emit(state + 1);
}

/// A complex state used to verify selector projection.
class UserState {
  final String name;
  final int age;

  const UserState({required this.name, required this.age});
}

/// A cubit that emits [UserState] values.
class UserCubit extends Cubit<UserState> {
  UserCubit() : super(const UserState(name: 'Alice', age: 30));

  void rename(String name) => emit(UserState(name: name, age: state.age));

  void birthday() => emit(UserState(name: state.name, age: state.age + 1));
}

/// A stateless component that calls [context.watch] and tracks build count.
class WatchingComponent extends StatelessComponent {
  final CounterCubit cubit;
  final void Function(int buildCount) onBuild;

  const WatchingComponent({
    required this.cubit,
    required this.onBuild,
    super.key,
  });

  @override
  Component build(BuildContext context) {
    final watched = context.watch<CounterCubit>();
    onBuild(watched.state);
    return div([Component.text('watched:${watched.state}')]);
  }
}

/// A stateless component that calls [context.read] and tracks build count.
///
/// Uses a [ValueKey] to force a fresh element when swapped in tests.
class ReadingComponent extends StatelessComponent {
  final CounterCubit cubit;
  final void Function() onBuild;

  const ReadingComponent({
    required this.cubit,
    required this.onBuild,
    super.key,
  });

  @override
  Component build(BuildContext context) {
    final bloc = context.read<CounterCubit>();
    onBuild();
    return div([Component.text('read:${bloc.state}')]);
  }
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('BuildContext.watch<T>()', () {
    group('subscribes to state changes', () {
      testComponents('component rebuilds when watched bloc emits new state', (
        tester,
      ) async {
        final cubit = CounterCubit();
        addTearDown(cubit.close);
        final builtStates = <int>[];

        tester.pumpComponent(
          BlocProvider<CounterCubit>.value(
            value: cubit,
            child: WatchingComponent(cubit: cubit, onBuild: builtStates.add),
          ),
        );

        builtStates.clear(); // Ignore initial build.

        cubit.increment();
        await tester.pump();

        expect(builtStates, equals([1]));
      });

      testComponents('renders updated state after emit', (tester) async {
        final cubit = CounterCubit();
        addTearDown(cubit.close);

        tester.pumpComponent(
          BlocProvider<CounterCubit>.value(
            value: cubit,
            child: WatchingComponent(cubit: cubit, onBuild: (_) {}),
          ),
        );

        expect(find.text('watched:0'), findsOneComponent);

        cubit.increment();
        await tester.pump();

        expect(find.text('watched:1'), findsOneComponent);
        expect(find.text('watched:0'), findsNothing);
      });

      testComponents(
        'only the watching component rebuilds, not siblings using read()',
        (tester) async {
          final cubit = CounterCubit();
          addTearDown(cubit.close);
          int watchBuildCount = 0;
          int readBuildCount = 0;

          tester.pumpComponent(
            BlocProvider<CounterCubit>.value(
              value: cubit,
              child: div([
                WatchingComponent(
                  cubit: cubit,
                  onBuild: (_) => watchBuildCount++,
                ),
                ReadingComponent(cubit: cubit, onBuild: () => readBuildCount++),
              ]),
            ),
          );

          watchBuildCount = 0;
          readBuildCount = 0;

          cubit.increment();
          await tester.pump();

          // Watcher rebuilt; reader did not.
          expect(watchBuildCount, equals(1));
          expect(readBuildCount, equals(0));
        },
      );
    });

    group('error handling', () {
      testComponents('throws when no provider found in context', (
        tester,
      ) async {
        final errors = <Object>[];

        tester.pumpComponent(
          Builder(
            builder: (context) {
              try {
                context.watch<CounterCubit>();
              } catch (e) {
                errors.add(e);
              }
              return const div([]);
            },
          ),
        );

        expect(errors, isNotEmpty);
      });
    });
  });

  group('BuildContext.select<T, S, R>()', () {
    group('returns selected value', () {
      testComponents('returns the correct initial selected value', (
        tester,
      ) async {
        final cubit = CounterCubit(7);
        addTearDown(cubit.close);
        int? capturedValue;

        tester.pumpComponent(
          BlocProvider<CounterCubit>.value(
            value: cubit,
            child: Builder(
              builder: (context) {
                capturedValue = context.select<CounterCubit, int, int>(
                  (state) => state * 2,
                );
                return div([Component.text('$capturedValue')]);
              },
            ),
          ),
        );

        expect(capturedValue, equals(14));
        expect(find.text('14'), findsOneComponent);
      });

      testComponents('updates returned value when state changes', (
        tester,
      ) async {
        final cubit = CounterCubit();
        addTearDown(cubit.close);

        tester.pumpComponent(
          BlocProvider<CounterCubit>.value(
            value: cubit,
            child: Builder(
              builder: (context) {
                final doubled = context.select<CounterCubit, int, int>(
                  (state) => state * 2,
                );
                return div([Component.text('doubled:$doubled')]);
              },
            ),
          ),
        );

        expect(find.text('doubled:0'), findsOneComponent);

        cubit.increment();
        await tester.pump();

        expect(find.text('doubled:2'), findsOneComponent);
        expect(find.text('doubled:0'), findsNothing);
      });
    });

    group('works with different selector functions', () {
      testComponents('boolean selector — parity projection', (tester) async {
        final cubit = CounterCubit();
        addTearDown(cubit.close);

        tester.pumpComponent(
          BlocProvider<CounterCubit>.value(
            value: cubit,
            child: Builder(
              builder: (context) {
                final isEven = context.select<CounterCubit, int, bool>(
                  (state) => state.isEven,
                );
                return div([Component.text('even:$isEven')]);
              },
            ),
          ),
        );

        expect(find.text('even:true'), findsOneComponent);

        cubit.increment();
        await tester.pump();

        expect(find.text('even:false'), findsOneComponent);
      });

      testComponents('string selector — projects field from complex state', (
        tester,
      ) async {
        final cubit = UserCubit();
        addTearDown(cubit.close);

        tester.pumpComponent(
          BlocProvider<UserCubit>.value(
            value: cubit,
            child: Builder(
              builder: (context) {
                final name = context.select<UserCubit, UserState, String>(
                  (state) => state.name,
                );
                return div([Component.text('name:$name')]);
              },
            ),
          ),
        );

        expect(find.text('name:Alice'), findsOneComponent);

        cubit.rename('Bob');
        await tester.pump();

        expect(find.text('name:Bob'), findsOneComponent);
      });

      testComponents(
        'two independent selectors on the same bloc both update correctly',
        (tester) async {
          final cubit = UserCubit();
          addTearDown(cubit.close);

          tester.pumpComponent(
            BlocProvider<UserCubit>.value(
              value: cubit,
              child: div([
                Builder(
                  builder: (context) {
                    final name = context.select<UserCubit, UserState, String>(
                      (state) => state.name,
                    );
                    return div([Component.text('name:$name')]);
                  },
                ),
                Builder(
                  builder: (context) {
                    final age = context.select<UserCubit, UserState, int>(
                      (state) => state.age,
                    );
                    return div([Component.text('age:$age')]);
                  },
                ),
              ]),
            ),
          );

          expect(find.text('name:Alice'), findsOneComponent);
          expect(find.text('age:30'), findsOneComponent);

          cubit.rename('Bob');
          await tester.pump();

          expect(find.text('name:Bob'), findsOneComponent);
          expect(find.text('age:30'), findsOneComponent);
        },
      );
    });

    group('subscribes to state changes', () {
      testComponents(
        'component that uses select() rebuilds when state changes',
        (tester) async {
          final cubit = CounterCubit();
          addTearDown(cubit.close);
          int buildCount = 0;

          tester.pumpComponent(
            BlocProvider<CounterCubit>.value(
              value: cubit,
              child: Builder(
                builder: (context) {
                  buildCount++;
                  context.select<CounterCubit, int, bool>(
                    (state) => state.isEven,
                  );
                  return const div([]);
                },
              ),
            ),
          );

          buildCount = 0;

          cubit.increment();
          await tester.pump();

          // Component subscribes to state changes via watch mechanism.
          expect(buildCount, greaterThan(0));
        },
      );
    });
  });
}
