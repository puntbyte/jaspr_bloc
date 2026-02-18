import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_bloc/jaspr_bloc.dart';
import 'package:jaspr_test/jaspr_test.dart';

// ---------------------------------------------------------------------------
// Test doubles
// ---------------------------------------------------------------------------

/// A complex state object used to verify selector isolation.
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

/// A simple integer-emitting cubit.
class CounterCubit extends Cubit<int> {
  CounterCubit([super.initialState = 0]);

  void increment() => emit(state + 1);
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('BlocSelector', () {
    group('initial render', () {
      testComponents('renders the initial selected value', (tester) async {
        final cubit = CounterCubit(7);
        addTearDown(cubit.close);

        tester.pumpComponent(
          BlocProvider<CounterCubit>.value(
            value: cubit,
            child: BlocSelector<CounterCubit, int, String>(
              selector: (state) => 'count:$state',
              builder: (context, value) {
                return div([Component.text(value)]);
              },
            ),
          ),
        );

        expect(find.text('count:7'), findsOneComponent);
      });
    });

    group('rebuild gating', () {
      testComponents('builder IS called when the selected value changes', (
        tester,
      ) async {
        final cubit = CounterCubit();
        addTearDown(cubit.close);
        final builtValues = <int>[];

        tester.pumpComponent(
          BlocProvider<CounterCubit>.value(
            value: cubit,
            child: BlocSelector<CounterCubit, int, int>(
              // Select the value as-is so every increment triggers a rebuild.
              selector: (state) => state,
              builder: (context, value) {
                builtValues.add(value);
                return div([Component.text('$value')]);
              },
            ),
          ),
        );

        builtValues.clear(); // Ignore initial build.

        cubit.increment();
        await tester.pump();

        expect(builtValues, equals([1]));
      });

      testComponents(
        'builder is NOT called when the selected value is unchanged',
        (tester) async {
          final cubit = CounterCubit();
          addTearDown(cubit.close);
          int buildCount = 0;

          tester.pumpComponent(
            BlocProvider<CounterCubit>.value(
              value: cubit,
              child: BlocSelector<CounterCubit, int, bool>(
                // Select whether the value is even — changes only on parity flip.
                selector: (state) => state.isEven,
                builder: (context, isEven) {
                  buildCount++;
                  return div([Component.text('even:$isEven')]);
                },
              ),
            ),
          );

          buildCount = 0; // Ignore initial build.

          // 0 → 1: parity changes (even → odd) → rebuild.
          cubit.increment();
          await tester.pump();
          expect(buildCount, equals(1));

          // 1 → 2: parity changes (odd → even) → rebuild.
          cubit.increment();
          await tester.pump();
          expect(buildCount, equals(2));

          // Directly emit a value with the same parity: even → even.
          // No parity change → no rebuild.
          cubit
            ..emit(4)
            ..emit(6);
          await tester.pump();
          expect(buildCount, equals(2));
        },
      );
    });

    group('complex state objects', () {
      testComponents('rebuilds only when the selected field changes', (
        tester,
      ) async {
        final cubit = UserCubit();
        addTearDown(cubit.close);
        final builtNames = <String>[];

        tester.pumpComponent(
          BlocProvider<UserCubit>.value(
            value: cubit,
            child: BlocSelector<UserCubit, UserState, String>(
              // Only select the name field.
              selector: (state) => state.name,
              builder: (context, name) {
                builtNames.add(name);
                return div([Component.text('name:$name')]);
              },
            ),
          ),
        );

        builtNames.clear(); // Ignore initial build.

        // Age changes — selected name is unchanged, no rebuild.
        cubit.birthday();
        await tester.pump();
        expect(builtNames, isEmpty);

        // Name changes — selected value differs, rebuild.
        cubit.rename('Bob');
        await tester.pump();
        expect(builtNames, equals(['Bob']));

        // Another age change — still no rebuild.
        cubit.birthday();
        await tester.pump();
        expect(builtNames, equals(['Bob']));
      });

      testComponents('can select independent fields with separate selectors', (
        tester,
      ) async {
        final cubit = UserCubit();
        addTearDown(cubit.close);
        int nameBuildCount = 0;
        int ageBuildCount = 0;

        tester.pumpComponent(
          BlocProvider<UserCubit>.value(
            value: cubit,
            child: div([
              BlocSelector<UserCubit, UserState, String>(
                selector: (state) => state.name,
                builder: (context, name) {
                  nameBuildCount++;
                  return div([Component.text('name:$name')]);
                },
              ),
              BlocSelector<UserCubit, UserState, int>(
                selector: (state) => state.age,
                builder: (context, age) {
                  ageBuildCount++;
                  return div([Component.text('age:$age')]);
                },
              ),
            ]),
          ),
        );

        nameBuildCount = 0;
        ageBuildCount = 0;

        // Age changes: only age selector rebuilds.
        cubit.birthday();
        await tester.pump();
        expect(nameBuildCount, equals(0));
        expect(ageBuildCount, equals(1));

        // Name changes: only name selector rebuilds.
        cubit.rename('Bob');
        await tester.pump();
        expect(nameBuildCount, equals(1));
        expect(ageBuildCount, equals(1));
      });
    });

    group('builder receives selected value', () {
      testComponents('builder receives T not S', (tester) async {
        final cubit = UserCubit();
        addTearDown(cubit.close);
        String? receivedValue;

        tester.pumpComponent(
          BlocProvider<UserCubit>.value(
            value: cubit,
            child: BlocSelector<UserCubit, UserState, String>(
              selector: (state) => state.name.toUpperCase(),
              builder: (context, value) {
                receivedValue = value;
                return div([Component.text(value)]);
              },
            ),
          ),
        );

        expect(receivedValue, equals('ALICE'));

        cubit.rename('bob');
        await tester.pump();

        expect(receivedValue, equals('BOB'));
      });
    });
  });
}
