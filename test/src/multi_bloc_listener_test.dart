import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_bloc/jaspr_bloc.dart';
import 'package:jaspr_test/jaspr_test.dart';

// ---------------------------------------------------------------------------
// Test doubles
// ---------------------------------------------------------------------------

/// A simple integer-emitting cubit.
class CounterCubit extends Cubit<int> {
  CounterCubit([super.initialState = 0]);

  void increment() => emit(state + 1);
}

/// A simple string-emitting cubit.
class NameCubit extends Cubit<String> {
  NameCubit([super.initialState = 'hello']);

  void update(String value) => emit(value);
}

/// A child component that counts how many times its [build] method is called.
class BuildCountComponent extends StatefulComponent {
  final void Function(int count) onBuild;

  const BuildCountComponent({required this.onBuild, super.key});

  @override
  State<BuildCountComponent> createState() => _BuildCountComponentState();
}

class _BuildCountComponentState extends State<BuildCountComponent> {
  int _count = 0;

  @override
  Component build(BuildContext context) {
    _count++;
    component.onBuild(_count);
    return const div([Component.text('child')]);
  }
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('MultiBlocListener', () {
    group('listener invocation', () {
      testComponents('each listener fires independently on its bloc change', (
        tester,
      ) async {
        final counterCubit = CounterCubit();
        final nameCubit = NameCubit();
        addTearDown(counterCubit.close);
        addTearDown(nameCubit.close);

        final counterStates = <int>[];
        final nameStates = <String>[];

        tester.pumpComponent(
          MultiBlocProvider(
            providers: [
              BlocProvider<CounterCubit>.value(value: counterCubit),
              BlocProvider<NameCubit>.value(value: nameCubit),
            ],
            child: MultiBlocListener(
              listeners: [
                BlocListener<CounterCubit, int>(
                  listener: (context, state) => counterStates.add(state),
                  child: const div([]),
                ),
                BlocListener<NameCubit, String>(
                  listener: (context, state) => nameStates.add(state),
                  child: const div([]),
                ),
              ],
              child: const div([Component.text('content')]),
            ),
          ),
        );

        counterCubit.increment();
        await tester.pump();

        expect(counterStates, equals([1]));
        expect(nameStates, isEmpty);

        nameCubit.update('world');
        await tester.pump();

        expect(counterStates, equals([1]));
        expect(nameStates, equals(['world']));
      });

      testComponents('both listeners fire when both blocs emit', (
        tester,
      ) async {
        final counterCubit = CounterCubit();
        final nameCubit = NameCubit();
        addTearDown(counterCubit.close);
        addTearDown(nameCubit.close);

        final counterStates = <int>[];
        final nameStates = <String>[];

        tester.pumpComponent(
          MultiBlocProvider(
            providers: [
              BlocProvider<CounterCubit>.value(value: counterCubit),
              BlocProvider<NameCubit>.value(value: nameCubit),
            ],
            child: MultiBlocListener(
              listeners: [
                BlocListener<CounterCubit, int>(
                  listener: (context, state) => counterStates.add(state),
                  child: const div([]),
                ),
                BlocListener<NameCubit, String>(
                  listener: (context, state) => nameStates.add(state),
                  child: const div([]),
                ),
              ],
              child: const div([]),
            ),
          ),
        );

        counterCubit.increment();
        nameCubit.update('world');
        await tester.pump();

        expect(counterStates, equals([1]));
        expect(nameStates, equals(['world']));
      });
    });

    group('child rendering', () {
      testComponents('single child is rendered on initial build', (
        tester,
      ) async {
        final cubit = CounterCubit();
        addTearDown(cubit.close);

        tester.pumpComponent(
          BlocProvider<CounterCubit>.value(
            value: cubit,
            child: MultiBlocListener(
              listeners: [
                BlocListener<CounterCubit, int>(
                  listener: (context, state) {},
                  child: const div([]),
                ),
              ],
              child: const div([Component.text('hello')]),
            ),
          ),
        );

        expect(find.text('hello'), findsOneComponent);
      });

      testComponents('child is NOT rebuilt when state changes', (tester) async {
        final counterCubit = CounterCubit();
        final nameCubit = NameCubit();
        addTearDown(counterCubit.close);
        addTearDown(nameCubit.close);

        int childBuildCount = 0;

        tester.pumpComponent(
          MultiBlocProvider(
            providers: [
              BlocProvider<CounterCubit>.value(value: counterCubit),
              BlocProvider<NameCubit>.value(value: nameCubit),
            ],
            child: MultiBlocListener(
              listeners: [
                BlocListener<CounterCubit, int>(
                  listener: (context, state) {},
                  child: const div([]),
                ),
                BlocListener<NameCubit, String>(
                  listener: (context, state) {},
                  child: const div([]),
                ),
              ],
              child: BuildCountComponent(
                onBuild: (count) {
                  childBuildCount = count;
                },
              ),
            ),
          ),
        );

        expect(childBuildCount, equals(1));

        counterCubit.increment();
        nameCubit.update('world');
        await tester.pump();

        // Child must not be rebuilt due to listeners.
        expect(childBuildCount, equals(1));
      });
    });

    group('listenWhen predicate', () {
      testComponents('listenWhen filters events for each listener', (
        tester,
      ) async {
        final cubit = CounterCubit();
        addTearDown(cubit.close);

        final evenStates = <int>[];
        final oddStates = <int>[];

        tester.pumpComponent(
          BlocProvider<CounterCubit>.value(
            value: cubit,
            child: MultiBlocListener(
              listeners: [
                BlocListener<CounterCubit, int>(
                  listenWhen: (prev, curr) => curr.isEven,
                  listener: (context, state) => evenStates.add(state),
                  child: const div([]),
                ),
                BlocListener<CounterCubit, int>(
                  listenWhen: (prev, curr) => curr.isOdd,
                  listener: (context, state) => oddStates.add(state),
                  child: const div([]),
                ),
              ],
              child: const div([]),
            ),
          ),
        );

        cubit.increment(); // 1 — odd
        await tester.pump();
        cubit.increment(); // 2 — even
        await tester.pump();
        cubit.increment(); // 3 — odd
        await tester.pump();

        expect(evenStates, equals([2]));
        expect(oddStates, equals([1, 3]));
      });
    });
  });
}
