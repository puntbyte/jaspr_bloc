import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_bloc/jaspr_bloc.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../helpers/client_mode.dart';

// ---------------------------------------------------------------------------
// Test doubles
// ---------------------------------------------------------------------------

/// A simple integer-emitting cubit.
class TestCubit extends Cubit<int> {
  TestCubit([super.initialState = 0]);

  void increment() => emit(state + 1);
}

/// A wrapper that can conditionally show or hide its child.
///
/// Hiding the child triggers the dispose lifecycle on the subtree.
class ConditionalWrapper extends StatefulComponent {
  final Component child;
  final void Function(ConditionalWrapperState state) onCreate;

  const ConditionalWrapper({
    required this.child,
    required this.onCreate,
    super.key,
  });

  @override
  State<ConditionalWrapper> createState() => ConditionalWrapperState();
}

class ConditionalWrapperState extends State<ConditionalWrapper> {
  bool _visible = true;

  /// Hides the child, triggering dispose on its subtree.
  void hide() {
    setState(() {
      _visible = false;
    });
  }

  @override
  void initState() {
    super.initState();
    component.onCreate(this);
  }

  @override
  Component build(BuildContext context) {
    if (_visible) {
      return component.child;
    }
    return const div([]);
  }
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  setUp(() => setIsClientForTesting(true));
  tearDown(() => resetIsClientForTesting());

  group('BlocConsumer', () {
    group('builder', () {
      testComponents('initial build renders current bloc state', (
        tester,
      ) async {
        final cubit = TestCubit(5);
        addTearDown(cubit.close);

        tester.pumpComponent(
          BlocProvider<TestCubit>.value(
            value: cubit,
            child: BlocConsumer<TestCubit, int>(
              listener: (context, state) {},
              builder: (context, state) {
                return div([Component.text('state:$state')]);
              },
            ),
          ),
        );

        expect(find.text('state:5'), findsOneComponent);
      });

      testComponents('builder rebuilds when bloc emits a new state', (
        tester,
      ) async {
        final cubit = TestCubit();
        addTearDown(cubit.close);

        tester.pumpComponent(
          BlocProvider<TestCubit>.value(
            value: cubit,
            child: BlocConsumer<TestCubit, int>(
              listener: (context, state) {},
              builder: (context, state) {
                return div([Component.text('state:$state')]);
              },
            ),
          ),
        );

        expect(find.text('state:0'), findsOneComponent);

        cubit.increment();
        await tester.pump();

        expect(find.text('state:1'), findsOneComponent);
      });

      testComponents('builder does not rebuild when buildWhen returns false', (
        tester,
      ) async {
        final cubit = TestCubit();
        addTearDown(cubit.close);
        final builtStates = <int>[];

        tester.pumpComponent(
          BlocProvider<TestCubit>.value(
            value: cubit,
            child: BlocConsumer<TestCubit, int>(
              // Only rebuild on even states.
              buildWhen: (prev, curr) => curr.isEven,
              listener: (context, state) {},
              builder: (context, state) {
                builtStates.add(state);
                return div([Component.text('state:$state')]);
              },
            ),
          ),
        );

        builtStates.clear(); // Ignore initial build.

        cubit.increment(); // 1 — odd, blocked by buildWhen.
        await tester.pump();
        expect(builtStates, isEmpty);

        cubit.increment(); // 2 — even, allowed.
        await tester.pump();
        expect(builtStates, equals([2]));
      });
    });

    group('listener', () {
      testComponents('listener is called when bloc emits a new state', (
        tester,
      ) async {
        final cubit = TestCubit();
        addTearDown(cubit.close);
        final listenedStates = <int>[];

        tester.pumpComponent(
          BlocProvider<TestCubit>.value(
            value: cubit,
            child: BlocConsumer<TestCubit, int>(
              listener: (context, state) => listenedStates.add(state),
              builder: (context, state) {
                return div([Component.text('state:$state')]);
              },
            ),
          ),
        );

        cubit.increment();
        await tester.pump();

        expect(listenedStates, equals([1]));
      });

      testComponents('listener is NOT called for the initial state', (
        tester,
      ) async {
        final cubit = TestCubit(42);
        addTearDown(cubit.close);
        final listenedStates = <int>[];

        tester.pumpComponent(
          BlocProvider<TestCubit>.value(
            value: cubit,
            child: BlocConsumer<TestCubit, int>(
              listener: (context, state) => listenedStates.add(state),
              builder: (context, state) {
                return div([Component.text('state:$state')]);
              },
            ),
          ),
        );

        expect(listenedStates, isEmpty);
      });

      testComponents('listener does not fire when listenWhen returns false', (
        tester,
      ) async {
        final cubit = TestCubit();
        addTearDown(cubit.close);
        final listenedStates = <int>[];

        tester.pumpComponent(
          BlocProvider<TestCubit>.value(
            value: cubit,
            child: BlocConsumer<TestCubit, int>(
              // Only listen on even states.
              listenWhen: (prev, curr) => curr.isEven,
              listener: (context, state) => listenedStates.add(state),
              builder: (context, state) {
                return div([Component.text('state:$state')]);
              },
            ),
          ),
        );

        cubit.increment(); // 1 — odd, blocked.
        await tester.pump();
        expect(listenedStates, isEmpty);

        cubit.increment(); // 2 — even, allowed.
        await tester.pump();
        expect(listenedStates, equals([2]));
      });
    });

    group('independent filtering', () {
      testComponents(
        'buildWhen and listenWhen filter independently per emission',
        (tester) async {
          final cubit = TestCubit();
          addTearDown(cubit.close);
          final builtStates = <int>[];
          final listenedStates = <int>[];

          tester.pumpComponent(
            BlocProvider<TestCubit>.value(
              value: cubit,
              child: BlocConsumer<TestCubit, int>(
                // Builder only accepts even states.
                buildWhen: (prev, curr) => curr.isEven,
                // Listener only accepts odd states.
                listenWhen: (prev, curr) => curr.isOdd,
                listener: (context, state) => listenedStates.add(state),
                builder: (context, state) {
                  builtStates.add(state);
                  return div([Component.text('state:$state')]);
                },
              ),
            ),
          );

          builtStates.clear(); // Ignore initial build.

          cubit.increment(); // 1 — odd: listener fires, no rebuild.
          await tester.pump();
          expect(listenedStates, equals([1]));
          expect(builtStates, isEmpty);

          cubit.increment(); // 2 — even: rebuild, listener silent.
          await tester.pump();
          expect(listenedStates, equals([1]));
          expect(builtStates, equals([2]));

          cubit.increment(); // 3 — odd: listener fires, no rebuild.
          await tester.pump();
          expect(listenedStates, equals([1, 3]));
          expect(builtStates, equals([2]));
        },
      );
    });

    group('single subscription', () {
      testComponents(
        'each state emission triggers at most one listener and one builder call',
        (tester) async {
          final cubit = TestCubit();
          addTearDown(cubit.close);
          int listenerCallCount = 0;
          int builderCallCount = 0;

          tester.pumpComponent(
            BlocProvider<TestCubit>.value(
              value: cubit,
              child: BlocConsumer<TestCubit, int>(
                listener: (context, state) => listenerCallCount++,
                builder: (context, state) {
                  builderCallCount++;
                  return div([Component.text('state:$state')]);
                },
              ),
            ),
          );

          builderCallCount = 0; // Ignore initial build.
          listenerCallCount = 0;

          cubit.increment();
          await tester.pump();

          expect(listenerCallCount, equals(1));
          expect(builderCallCount, equals(1));

          cubit.increment();
          await tester.pump();

          expect(listenerCallCount, equals(2));
          expect(builderCallCount, equals(2));
        },
      );
    });

    group('dispose', () {
      testComponents('cancels subscription on dispose without errors', (
        tester,
      ) async {
        final cubit = TestCubit();
        addTearDown(cubit.close);
        ConditionalWrapperState? wrapperState;

        tester.pumpComponent(
          ConditionalWrapper(
            onCreate: (state) => wrapperState = state,
            child: BlocProvider<TestCubit>.value(
              value: cubit,
              child: BlocConsumer<TestCubit, int>(
                listener: (context, state) {},
                builder: (context, state) {
                  return div([Component.text('state:$state')]);
                },
              ),
            ),
          ),
        );

        expect(find.text('state:0'), findsOneComponent);

        // Dispose the BlocConsumer by hiding its parent.
        wrapperState!.hide();
        await tester.pump();

        // After dispose, emitting on the cubit should not throw.
        cubit.increment();
        await tester.pump();
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
        final listenedStates = <int>[];

        tester.pumpComponent(
          BlocProvider<TestCubit>.value(
            value: contextCubit,
            child: BlocConsumer<TestCubit, int>(
              bloc: explicitCubit,
              listener: (context, state) => listenedStates.add(state),
              builder: (context, state) {
                return div([Component.text('state:$state')]);
              },
            ),
          ),
        );

        expect(find.text('state:0'), findsOneComponent);

        // Emitting on context bloc should NOT trigger listener or rebuild.
        contextCubit.increment();
        await tester.pump();
        expect(listenedStates, isEmpty);
        expect(find.text('state:0'), findsOneComponent);

        // Emitting on explicit bloc SHOULD trigger listener and rebuild.
        explicitCubit.increment();
        await tester.pump();
        expect(listenedStates, equals([1]));
        expect(find.text('state:1'), findsOneComponent);
      });
    });
  });
}
