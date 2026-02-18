import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_bloc/jaspr_bloc.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../helpers/client_mode.dart';

// ---------------------------------------------------------------------------
// Test doubles
// ---------------------------------------------------------------------------

/// A simple test cubit that emits integers.
class TestCubit extends Cubit<int> {
  TestCubit([super.initialState = 0]);

  void increment() => emit(state + 1);

  void emit10() => emit(10);
}

/// A parent component that conditionally shows or hides its child.
///
/// Used to trigger the dispose lifecycle on nested components via Jaspr's
/// reconciliation.
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

  /// Hides the child component, triggering dispose on its subtree.
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

/// A component that counts how many times its [build] method is called.
class BuildCountTracker extends StatefulComponent {
  final void Function(int count) onBuild;

  const BuildCountTracker({required this.onBuild, super.key});

  @override
  State<BuildCountTracker> createState() => _BuildCountTrackerState();
}

class _BuildCountTrackerState extends State<BuildCountTracker> {
  int _count = 0;

  @override
  Component build(BuildContext context) {
    _count++;
    component.onBuild(_count);
    return const div([]);
  }
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  setUp(() => setIsClientForTesting(true));
  tearDown(() => resetIsClientForTesting());

  group('BlocBuilder', () {
    group('initial render', () {
      testComponents(
        'renders with the bloc initial state from context lookup',
        (tester) async {
          final cubit = TestCubit(42);
          addTearDown(cubit.close);

          tester.pumpComponent(
            BlocProvider<TestCubit>.value(
              value: cubit,
              child: BlocBuilder<TestCubit, int>(
                builder: (context, state) {
                  return div([Component.text('State: $state')]);
                },
              ),
            ),
          );

          expect(find.text('State: 42'), findsOneComponent);
        },
      );

      testComponents(
        'renders with the bloc initial state when bloc is provided explicitly',
        (tester) async {
          final cubit = TestCubit(7);
          addTearDown(cubit.close);

          tester.pumpComponent(
            BlocBuilder<TestCubit, int>(
              bloc: cubit,
              builder: (context, state) {
                return div([Component.text('State: $state')]);
              },
            ),
          );

          expect(find.text('State: 7'), findsOneComponent);
        },
      );
    });

    group('rebuilds on state change', () {
      testComponents('displays new state after emit', (tester) async {
        final cubit = TestCubit();
        addTearDown(cubit.close);

        tester.pumpComponent(
          BlocProvider<TestCubit>.value(
            value: cubit,
            child: BlocBuilder<TestCubit, int>(
              builder: (context, state) {
                return div([Component.text('State: $state')]);
              },
            ),
          ),
        );

        expect(find.text('State: 0'), findsOneComponent);

        cubit.increment();
        await tester.pump();

        expect(find.text('State: 1'), findsOneComponent);
        expect(find.text('State: 0'), findsNothing);
      });

      testComponents('updates correctly on multiple emissions', (tester) async {
        final cubit = TestCubit();
        addTearDown(cubit.close);

        tester.pumpComponent(
          BlocProvider<TestCubit>.value(
            value: cubit,
            child: BlocBuilder<TestCubit, int>(
              builder: (context, state) {
                return div([Component.text('Count: $state')]);
              },
            ),
          ),
        );

        cubit.increment();
        await tester.pump();
        expect(find.text('Count: 1'), findsOneComponent);

        cubit.increment();
        await tester.pump();
        expect(find.text('Count: 2'), findsOneComponent);
      });
    });

    group('buildWhen', () {
      testComponents('prevents rebuild when buildWhen returns false', (
        tester,
      ) async {
        final cubit = TestCubit();
        addTearDown(cubit.close);

        tester.pumpComponent(
          BlocProvider<TestCubit>.value(
            value: cubit,
            child: BlocBuilder<TestCubit, int>(
              // Only rebuild when state reaches 10.
              buildWhen: (previous, current) => current == 10,
              builder: (context, state) {
                return div([Component.text('State: $state')]);
              },
            ),
          ),
        );

        expect(find.text('State: 0'), findsOneComponent);

        // Emit state 1 — buildWhen returns false, should NOT rebuild.
        cubit.increment();
        await tester.pump();
        expect(find.text('State: 0'), findsOneComponent);
        expect(find.text('State: 1'), findsNothing);

        // Emit state 10 — buildWhen returns true, should rebuild.
        cubit.emit10();
        await tester.pump();
        expect(find.text('State: 10'), findsOneComponent);
        expect(find.text('State: 0'), findsNothing);
      });

      testComponents('allows rebuild when buildWhen returns true', (
        tester,
      ) async {
        final cubit = TestCubit();
        addTearDown(cubit.close);

        tester.pumpComponent(
          BlocProvider<TestCubit>.value(
            value: cubit,
            child: BlocBuilder<TestCubit, int>(
              buildWhen: (previous, current) => current > previous,
              builder: (context, state) {
                return div([Component.text('State: $state')]);
              },
            ),
          ),
        );

        cubit.increment();
        await tester.pump();
        expect(find.text('State: 1'), findsOneComponent);
      });
    });

    group('explicit bloc parameter', () {
      testComponents('uses explicit bloc instead of context lookup', (
        tester,
      ) async {
        final contextCubit = TestCubit(100);
        final explicitCubit = TestCubit(5);
        addTearDown(contextCubit.close);
        addTearDown(explicitCubit.close);

        tester.pumpComponent(
          BlocProvider<TestCubit>.value(
            value: contextCubit,
            child: BlocBuilder<TestCubit, int>(
              bloc: explicitCubit,
              builder: (context, state) {
                return div([Component.text('State: $state')]);
              },
            ),
          ),
        );

        // Should display explicit bloc's state, not the context bloc's state.
        expect(find.text('State: 5'), findsOneComponent);
        expect(find.text('State: 100'), findsNothing);
      });

      testComponents('rebuilds when explicit bloc emits', (tester) async {
        final cubit = TestCubit();
        addTearDown(cubit.close);

        tester.pumpComponent(
          BlocBuilder<TestCubit, int>(
            bloc: cubit,
            builder: (context, state) {
              return div([Component.text('State: $state')]);
            },
          ),
        );

        cubit.increment();
        await tester.pump();
        expect(find.text('State: 1'), findsOneComponent);
      });
    });

    group('dispose', () {
      testComponents('subscription is cleaned up on dispose', (tester) async {
        final cubit = TestCubit();
        addTearDown(cubit.close);
        ConditionalWrapperState? wrapperState;
        int buildCallCount = 0;

        tester.pumpComponent(
          ConditionalWrapper(
            onCreate: (state) {
              wrapperState = state;
            },
            child: BlocProvider<TestCubit>.value(
              value: cubit,
              child: BlocBuilder<TestCubit, int>(
                builder: (context, state) {
                  buildCallCount++;
                  return div([Component.text('State: $state')]);
                },
              ),
            ),
          ),
        );

        final buildCountBeforeDispose = buildCallCount;

        // Dispose the BlocBuilder subtree via reconciliation.
        wrapperState!.hide();
        await tester.pump();

        // Emit after dispose — should NOT trigger additional builds.
        cubit.increment();
        await tester.pump();

        expect(buildCallCount, equals(buildCountBeforeDispose));
      });
    });
  });
}
