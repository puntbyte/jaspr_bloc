import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_bloc/jaspr_bloc.dart';
import 'package:jaspr_test/jaspr_test.dart';

// ---------------------------------------------------------------------------
// Test doubles
// ---------------------------------------------------------------------------

/// A simple test cubit that emits integers.
class TestCubit extends Cubit<int> {
  TestCubit([super.initialState = 0]);

  void increment() => emit(state + 1);
}

/// A child component that counts how many times its [build] method is called.
///
/// Used to verify that [BlocListener] does not cause its child to rebuild on
/// state changes.
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
  group('BlocListener', () {
    group('listener invocation', () {
      testComponents('listener is called when bloc emits a new state', (
        tester,
      ) async {
        final cubit = TestCubit();
        addTearDown(cubit.close);
        final states = <int>[];

        tester.pumpComponent(
          BlocProvider<TestCubit>.value(
            value: cubit,
            child: BlocListener<TestCubit, int>(
              listener: (context, state) => states.add(state),
              child: const div([]),
            ),
          ),
        );

        cubit.increment();
        await tester.pump();

        expect(states, equals([1]));
      });

      testComponents('listener is called on multiple state emissions', (
        tester,
      ) async {
        final cubit = TestCubit();
        addTearDown(cubit.close);
        final states = <int>[];

        tester.pumpComponent(
          BlocProvider<TestCubit>.value(
            value: cubit,
            child: BlocListener<TestCubit, int>(
              listener: (context, state) => states.add(state),
              child: const div([]),
            ),
          ),
        );

        cubit.increment();
        await tester.pump();
        cubit.increment();
        await tester.pump();

        expect(states, equals([1, 2]));
      });
    });

    group('initial state', () {
      testComponents('listener is NOT called for the initial state', (
        tester,
      ) async {
        final cubit = TestCubit(42);
        addTearDown(cubit.close);
        final states = <int>[];

        tester.pumpComponent(
          BlocProvider<TestCubit>.value(
            value: cubit,
            child: BlocListener<TestCubit, int>(
              listener: (context, state) => states.add(state),
              child: const div([]),
            ),
          ),
        );

        // No pump needed — initial state should never fire the listener.
        expect(states, isEmpty);
      });
    });

    group('listenWhen', () {
      testComponents('prevents listener call when listenWhen returns false', (
        tester,
      ) async {
        final cubit = TestCubit();
        addTearDown(cubit.close);
        final states = <int>[];

        tester.pumpComponent(
          BlocProvider<TestCubit>.value(
            value: cubit,
            child: BlocListener<TestCubit, int>(
              // Only listen when state is even.
              listenWhen: (previous, current) => current.isEven,
              listener: (context, state) => states.add(state),
              child: const div([]),
            ),
          ),
        );

        // Emit 1 — odd, listenWhen returns false.
        cubit.increment();
        await tester.pump();
        expect(states, isEmpty);

        // Emit 2 — even, listenWhen returns true.
        cubit.increment();
        await tester.pump();
        expect(states, equals([2]));
      });

      testComponents('allows listener call when listenWhen returns true', (
        tester,
      ) async {
        final cubit = TestCubit();
        addTearDown(cubit.close);
        final states = <int>[];

        tester.pumpComponent(
          BlocProvider<TestCubit>.value(
            value: cubit,
            child: BlocListener<TestCubit, int>(
              listenWhen: (previous, current) => current > previous,
              listener: (context, state) => states.add(state),
              child: const div([]),
            ),
          ),
        );

        cubit.increment();
        await tester.pump();

        expect(states, equals([1]));
      });
    });

    group('child rendering', () {
      testComponents('child is rendered on initial build', (tester) async {
        final cubit = TestCubit();
        addTearDown(cubit.close);

        tester.pumpComponent(
          BlocProvider<TestCubit>.value(
            value: cubit,
            child: BlocListener<TestCubit, int>(
              listener: (context, state) {},
              child: const div([Component.text('hello')]),
            ),
          ),
        );

        expect(find.text('hello'), findsOneComponent);
      });

      testComponents('child is NOT rebuilt when state changes', (tester) async {
        final cubit = TestCubit();
        addTearDown(cubit.close);
        int childBuildCount = 0;

        tester.pumpComponent(
          BlocProvider<TestCubit>.value(
            value: cubit,
            child: BlocListener<TestCubit, int>(
              listener: (context, state) {},
              child: BuildCountComponent(
                onBuild: (count) {
                  childBuildCount = count;
                },
              ),
            ),
          ),
        );

        expect(childBuildCount, equals(1));

        cubit.increment();
        await tester.pump();

        // Child should not have been rebuilt due to the listener.
        expect(childBuildCount, equals(1));
      });
    });

    group('explicit bloc parameter', () {
      testComponents('uses explicit bloc instead of context lookup', (
        tester,
      ) async {
        final contextCubit = TestCubit(100);
        final explicitCubit = TestCubit(0);
        addTearDown(contextCubit.close);
        addTearDown(explicitCubit.close);
        final states = <int>[];

        tester.pumpComponent(
          BlocProvider<TestCubit>.value(
            value: contextCubit,
            child: BlocListener<TestCubit, int>(
              bloc: explicitCubit,
              listener: (context, state) => states.add(state),
              child: const div([]),
            ),
          ),
        );

        // Emitting on context bloc should NOT trigger the listener.
        contextCubit.increment();
        await tester.pump();
        expect(states, isEmpty);

        // Emitting on explicit bloc SHOULD trigger the listener.
        explicitCubit.increment();
        await tester.pump();
        expect(states, equals([1]));
      });
    });
  });
}
