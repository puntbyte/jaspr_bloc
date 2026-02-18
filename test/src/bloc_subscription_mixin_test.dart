import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_bloc/jaspr_bloc.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../helpers/client_mode.dart';

/// A simple test cubit that emits integers.
class TestCubit extends Cubit<int> {
  TestCubit() : super(0);

  void increment() => emit(state + 1);
  void decrement() => emit(state - 1);
}

/// A test component that uses [BlocSubscriptionMixin].
class TestSubscriptionComponent extends StatefulComponent {
  final TestCubit cubit;
  final void Function(int state)? onState;
  final bool Function(int previous, int current)? filter;

  const TestSubscriptionComponent({
    required this.cubit,
    this.onState,
    this.filter,
    super.key,
  });

  @override
  State<TestSubscriptionComponent> createState() =>
      _TestSubscriptionComponentState();
}

class _TestSubscriptionComponentState extends State<TestSubscriptionComponent>
    with BlocSubscriptionMixin {
  int? lastReceivedState;

  @override
  void initState() {
    super.initState();
    subscribeTo<TestCubit, int>(
      component.cubit,
      onState: (state) {
        lastReceivedState = state;
        if (component.onState != null) {
          component.onState!(state);
        }
      },
      filter: component.filter,
    );
  }

  @override
  Component build(BuildContext context) {
    return div([Component.text('Last state: $lastReceivedState')]);
  }
}

void main() {
  setUp(() => setIsClientForTesting(true));
  tearDown(() => resetIsClientForTesting());

  group('BlocSubscriptionMixin', () {
    late TestCubit cubit;

    setUp(() {
      cubit = TestCubit();
    });

    tearDown(() {
      cubit.close();
    });

    testComponents('subscription receives state changes', (tester) async {
      final receivedStates = <int>[];

      tester.pumpComponent(
        TestSubscriptionComponent(
          cubit: cubit,
          onState: (state) => receivedStates.add(state),
        ),
      );

      // Initial state should not trigger callback
      expect(receivedStates, isEmpty);

      // Emit new states
      cubit.increment();
      await Future<void>.delayed(Duration.zero);

      expect(receivedStates, [1]);

      cubit.increment();
      await Future<void>.delayed(Duration.zero);

      expect(receivedStates, [1, 2]);

      cubit.decrement();
      await Future<void>.delayed(Duration.zero);

      expect(receivedStates, [1, 2, 1]);
    });

    testComponents('filter predicate prevents callback when returning false', (
      tester,
    ) async {
      final receivedStates = <int>[];

      tester.pumpComponent(
        TestSubscriptionComponent(
          cubit: cubit,
          onState: (state) => receivedStates.add(state),
          // Only allow even numbers
          filter: (previous, current) => current.isEven,
        ),
      );

      expect(receivedStates, isEmpty);

      // This should be filtered out (1 is odd)
      cubit.increment();
      await Future<void>.delayed(Duration.zero);

      expect(receivedStates, isEmpty);

      // This should pass through (2 is even)
      cubit.increment();
      await Future<void>.delayed(Duration.zero);

      expect(receivedStates, [2]);

      // This should be filtered out (3 is odd)
      cubit.increment();
      await Future<void>.delayed(Duration.zero);

      expect(receivedStates, [2]);

      // This should pass through (4 is even)
      cubit.increment();
      await Future<void>.delayed(Duration.zero);

      expect(receivedStates, [2, 4]);
    });

    testComponents('subscription is cancelled on dispose', (tester) async {
      final receivedStates = <int>[];
      var componentMounted = true;

      tester.pumpComponent(
        TestSubscriptionComponent(
          cubit: cubit,
          onState: (state) {
            if (componentMounted) {
              receivedStates.add(state);
            }
          },
        ),
      );

      expect(receivedStates, isEmpty);

      // Emit state while component is mounted
      cubit.increment();
      await Future<void>.delayed(Duration.zero);

      expect(receivedStates, [1]);

      // Unmount the component (which should cancel subscription)
      componentMounted = false;
      tester.pumpComponent(const div([]));

      // Emit state after component is unmounted
      cubit.increment();
      await Future<void>.delayed(Duration.zero);

      // Should still be [1] because subscription was cancelled
      expect(receivedStates, [1]);
    });

    testComponents('filter receives previous and current state correctly', (
      tester,
    ) async {
      final filterCalls = <({int previous, int current})>[];

      tester.pumpComponent(
        TestSubscriptionComponent(
          cubit: cubit,
          filter: (previous, current) {
            filterCalls.add((previous: previous, current: current));
            return true;
          },
        ),
      );

      cubit.increment(); // 0 -> 1
      await Future<void>.delayed(Duration.zero);

      expect(filterCalls.length, 1);
      expect(filterCalls[0].previous, 0);
      expect(filterCalls[0].current, 1);

      cubit.increment(); // 1 -> 2
      await Future<void>.delayed(Duration.zero);

      expect(filterCalls.length, 2);
      expect(filterCalls[1].previous, 1);
      expect(filterCalls[1].current, 2);

      cubit.decrement(); // 2 -> 1
      await Future<void>.delayed(Duration.zero);

      expect(filterCalls.length, 3);
      expect(filterCalls[2].previous, 2);
      expect(filterCalls[2].current, 1);
    });
  });
}
