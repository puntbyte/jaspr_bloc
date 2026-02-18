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

// ---------------------------------------------------------------------------
// Tests
//
// These tests run without calling setIsClientForTesting, so isClientEnvironment
// defaults to kIsWeb = false (Dart VM). This simulates a server-side rendering
// (SSR) environment where no stream subscriptions should be activated.
// ---------------------------------------------------------------------------

void main() {
  group('SSR — BlocBuilder', () {
    testComponents('renders with initial state synchronously', (tester) async {
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
    });

    testComponents(
      'does not rebuild when bloc emits a new state (no subscription)',
      (tester) async {
        final cubit = TestCubit(0);
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

        // Emit new state — no subscription exists, so no rebuild should occur.
        cubit.increment();
        await tester.pump();

        expect(find.text('State: 0'), findsOneComponent);
        expect(find.text('State: 1'), findsNothing);
      },
    );

    testComponents('buildWhen is not invoked during SSR', (tester) async {
      final cubit = TestCubit(0);
      addTearDown(cubit.close);
      var buildWhenCallCount = 0;

      tester.pumpComponent(
        BlocProvider<TestCubit>.value(
          value: cubit,
          child: BlocBuilder<TestCubit, int>(
            buildWhen: (previous, current) {
              buildWhenCallCount++;
              return true;
            },
            builder: (context, state) {
              return div([Component.text('State: $state')]);
            },
          ),
        ),
      );

      cubit.increment();
      await tester.pump();

      // No subscription means buildWhen is never called.
      expect(buildWhenCallCount, equals(0));
    });
  });

  group('SSR — BlocListener', () {
    testComponents('listener is never called during SSR', (tester) async {
      final cubit = TestCubit(0);
      addTearDown(cubit.close);
      final listenerCalls = <int>[];

      tester.pumpComponent(
        BlocProvider<TestCubit>.value(
          value: cubit,
          child: BlocListener<TestCubit, int>(
            listener: (context, state) => listenerCalls.add(state),
            child: const div([]),
          ),
        ),
      );

      // Emit a new state — listener should remain inert during SSR.
      cubit.increment();
      await tester.pump();

      expect(listenerCalls, isEmpty);
    });

    testComponents('child renders without listener being invoked', (
      tester,
    ) async {
      final cubit = TestCubit(0);
      addTearDown(cubit.close);

      tester.pumpComponent(
        BlocProvider<TestCubit>.value(
          value: cubit,
          child: BlocListener<TestCubit, int>(
            listener: (context, state) {},
            child: const div([Component.text('child content')]),
          ),
        ),
      );

      expect(find.text('child content'), findsOneComponent);
    });
  });

  group('SSR — BlocConsumer', () {
    testComponents(
      'renders initial state and listener is not invoked during SSR',
      (tester) async {
        final cubit = TestCubit(7);
        addTearDown(cubit.close);
        final listenerCalls = <int>[];

        tester.pumpComponent(
          BlocProvider<TestCubit>.value(
            value: cubit,
            child: BlocConsumer<TestCubit, int>(
              listener: (context, state) => listenerCalls.add(state),
              builder: (context, state) {
                return div([Component.text('State: $state')]);
              },
            ),
          ),
        );

        expect(find.text('State: 7'), findsOneComponent);

        cubit.increment();
        await tester.pump();

        // No subscription — UI does not update and listener is not called.
        expect(find.text('State: 7'), findsOneComponent);
        expect(find.text('State: 8'), findsNothing);
        expect(listenerCalls, isEmpty);
      },
    );
  });

  group('SSR — BlocProvider', () {
    testComponents(
      'bloc is accessible via context.read() without subscription',
      (tester) async {
        final cubit = TestCubit(99);
        addTearDown(cubit.close);
        int? readState;

        tester.pumpComponent(
          BlocProvider<TestCubit>.value(
            value: cubit,
            child: Builder(
              builder: (context) {
                readState = context.read<TestCubit>().state;
                return div([Component.text('$readState')]);
              },
            ),
          ),
        );

        expect(readState, equals(99));
        expect(find.text('99'), findsOneComponent);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // Client Hydration tests
  //
  // These tests simulate the client environment (isClientEnvironment = true)
  // to verify that after SSR hydration, components activate subscriptions and
  // become reactive. The initial state rendered matches what SSR would have
  // produced, and subsequent events trigger reactive updates.
  // ---------------------------------------------------------------------------

  group('Client Hydration — BlocBuilder', () {
    setUp(() => setIsClientForTesting(true));
    tearDown(() => resetIsClientForTesting());

    testComponents('renders initial state matching SSR output on hydration', (
      tester,
    ) async {
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

      // Initial render uses bloc.state, matching what SSR would render.
      expect(find.text('State: 42'), findsOneComponent);
    });

    testComponents(
      'becomes reactive and rebuilds on new states after hydration',
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

        // Post-hydration: new events trigger reactive rebuilds.
        cubit.increment();
        await tester.pump();

        expect(find.text('State: 43'), findsOneComponent);
        expect(find.text('State: 42'), findsNothing);
      },
    );
  });

  group('Client Hydration — BlocListener', () {
    setUp(() => setIsClientForTesting(true));
    tearDown(() => resetIsClientForTesting());

    testComponents('does not fire listener on initial hydration mount', (
      tester,
    ) async {
      final cubit = TestCubit(0);
      addTearDown(cubit.close);
      final listenerCalls = <int>[];

      tester.pumpComponent(
        BlocProvider<TestCubit>.value(
          value: cubit,
          child: BlocListener<TestCubit, int>(
            listener: (context, state) => listenerCalls.add(state),
            child: const div([]),
          ),
        ),
      );

      // Listener is not invoked at mount time — only on new emissions.
      expect(listenerCalls, isEmpty);
    });

    testComponents('begins invoking listener on new states after hydration', (
      tester,
    ) async {
      final cubit = TestCubit(0);
      addTearDown(cubit.close);
      final listenerCalls = <int>[];

      tester.pumpComponent(
        BlocProvider<TestCubit>.value(
          value: cubit,
          child: BlocListener<TestCubit, int>(
            listener: (context, state) => listenerCalls.add(state),
            child: const div([]),
          ),
        ),
      );

      expect(listenerCalls, isEmpty);

      // Post-hydration: new events invoke the listener.
      cubit.increment();
      await tester.pump();

      expect(listenerCalls, equals([1]));
    });
  });

  group('Client Hydration — BlocConsumer', () {
    setUp(() => setIsClientForTesting(true));
    tearDown(() => resetIsClientForTesting());

    testComponents('renders server state initially and reacts post-hydration', (
      tester,
    ) async {
      final cubit = TestCubit(7);
      addTearDown(cubit.close);
      final listenerCalls = <int>[];

      tester.pumpComponent(
        BlocProvider<TestCubit>.value(
          value: cubit,
          child: BlocConsumer<TestCubit, int>(
            listener: (context, state) => listenerCalls.add(state),
            builder: (context, state) {
              return div([Component.text('State: $state')]);
            },
          ),
        ),
      );

      // Initial render matches the SSR state; listener not yet invoked.
      expect(find.text('State: 7'), findsOneComponent);
      expect(listenerCalls, isEmpty);

      // Post-hydration: new events trigger both a rebuild and listener call.
      cubit.increment();
      await tester.pump();

      expect(find.text('State: 8'), findsOneComponent);
      expect(find.text('State: 7'), findsNothing);
      expect(listenerCalls, equals([8]));
    });
  });
}
