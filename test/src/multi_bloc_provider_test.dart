import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_bloc/jaspr_bloc.dart';
import 'package:jaspr_test/jaspr_test.dart';

// ---------------------------------------------------------------------------
// Test doubles
// ---------------------------------------------------------------------------

/// A simple test cubit that emits integers.
class CounterCubit extends Cubit<int> {
  CounterCubit() : super(0);
}

/// A second distinct test cubit.
class NameCubit extends Cubit<String> {
  NameCubit() : super('hello');
}

/// A third distinct test cubit.
class FlagCubit extends Cubit<bool> {
  FlagCubit() : super(false);
}

/// A component that reads all three blocs and renders their states.
class MultiReaderComponent extends StatelessComponent {
  const MultiReaderComponent({super.key});

  @override
  Component build(BuildContext context) {
    final counter = BlocProvider.of<CounterCubit>(context);
    final name = BlocProvider.of<NameCubit>(context);
    final flag = BlocProvider.of<FlagCubit>(context);
    return div([
      Component.text('counter:${counter.state}'),
      Component.text('name:${name.state}'),
      Component.text('flag:${flag.state}'),
    ]);
  }
}

/// A component that reads only [CounterCubit] and [NameCubit].
class TwoReaderComponent extends StatelessComponent {
  const TwoReaderComponent({super.key});

  @override
  Component build(BuildContext context) {
    final counter = BlocProvider.of<CounterCubit>(context);
    final name = BlocProvider.of<NameCubit>(context);
    return div([
      Component.text('counter:${counter.state}'),
      Component.text('name:${name.state}'),
    ]);
  }
}

/// Captures a bloc reference on first build for lifecycle inspection.
class BlocCapture<T extends BlocBase<Object?>> extends StatefulComponent {
  final void Function(T bloc) onCapture;

  const BlocCapture({required this.onCapture, super.key});

  @override
  State<BlocCapture<T>> createState() => _BlocCaptureState<T>();
}

class _BlocCaptureState<T extends BlocBase<Object?>>
    extends State<BlocCapture<T>> {
  bool _captured = false;

  @override
  Component build(BuildContext context) {
    if (!_captured) {
      _captured = true;
      component.onCapture(BlocProvider.of<T>(context));
    }
    return const div([]);
  }
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

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('MultiBlocProvider', () {
    testComponents('all blocs from the list are accessible from child', (
      tester,
    ) async {
      tester.pumpComponent(
        MultiBlocProvider(
          providers: [
            BlocProvider<CounterCubit>(create: (_) => CounterCubit()),
            BlocProvider<NameCubit>(create: (_) => NameCubit()),
            BlocProvider<FlagCubit>(create: (_) => FlagCubit()),
          ],
          child: const MultiReaderComponent(),
        ),
      );

      expect(find.text('counter:0'), findsOneComponent);
      expect(find.text('name:hello'), findsOneComponent);
      expect(find.text('flag:false'), findsOneComponent);
    });

    testComponents('all blocs are accessible from a deeply nested child', (
      tester,
    ) async {
      tester.pumpComponent(
        MultiBlocProvider(
          providers: [
            BlocProvider<CounterCubit>(create: (_) => CounterCubit()),
            BlocProvider<NameCubit>(create: (_) => NameCubit()),
          ],
          child: const div([
            div([
              div([TwoReaderComponent()]),
            ]),
          ]),
        ),
      );

      expect(find.text('counter:0'), findsOneComponent);
      expect(find.text('name:hello'), findsOneComponent);
    });

    testComponents('provider ordering does not affect access', (tester) async {
      // Reversed order: NameCubit first, CounterCubit second — both still
      // accessible regardless of position in the list.
      tester.pumpComponent(
        MultiBlocProvider(
          providers: [
            BlocProvider<NameCubit>(create: (_) => NameCubit()),
            BlocProvider<CounterCubit>(create: (_) => CounterCubit()),
          ],
          child: Builder(
            builder: (context) {
              final counter = BlocProvider.of<CounterCubit>(context);
              final name = BlocProvider.of<NameCubit>(context);
              return div([
                Component.text('counter:${counter.state}'),
                Component.text('name:${name.state}'),
              ]);
            },
          ),
        ),
      );

      expect(find.text('counter:0'), findsOneComponent);
      expect(find.text('name:hello'), findsOneComponent);
    });

    testComponents('auto-close behavior is preserved for each provider', (
      tester,
    ) async {
      CounterCubit? capturedCounter;
      NameCubit? capturedName;
      ConditionalWrapperState? wrapperState;

      tester.pumpComponent(
        ConditionalWrapper(
          onCreate: (state) {
            wrapperState = state;
          },
          child: MultiBlocProvider(
            providers: [
              BlocProvider<CounterCubit>(create: (_) => CounterCubit()),
              BlocProvider<NameCubit>(create: (_) => NameCubit()),
            ],
            child: div([
              BlocCapture<CounterCubit>(
                onCapture: (bloc) {
                  capturedCounter = bloc;
                },
              ),
              BlocCapture<NameCubit>(
                onCapture: (bloc) {
                  capturedName = bloc;
                },
              ),
            ]),
          ),
        ),
      );

      expect(capturedCounter, isNotNull);
      expect(capturedName, isNotNull);
      expect(capturedCounter!.isClosed, isFalse);
      expect(capturedName!.isClosed, isFalse);

      // Hide the MultiBlocProvider to trigger dispose via reconciliation.
      wrapperState!.hide();
      await tester.pump();

      expect(capturedCounter!.isClosed, isTrue);
      expect(capturedName!.isClosed, isTrue);
    });

    testComponents('value providers are NOT closed on dispose', (tester) async {
      final counter = CounterCubit();
      final name = NameCubit();
      addTearDown(counter.close);
      addTearDown(name.close);

      ConditionalWrapperState? wrapperState;

      tester.pumpComponent(
        ConditionalWrapper(
          onCreate: (state) {
            wrapperState = state;
          },
          child: MultiBlocProvider(
            providers: [
              BlocProvider<CounterCubit>.value(value: counter),
              BlocProvider<NameCubit>.value(value: name),
            ],
            child: const TwoReaderComponent(),
          ),
        ),
      );

      expect(counter.isClosed, isFalse);
      expect(name.isClosed, isFalse);

      wrapperState!.hide();
      await tester.pump();

      expect(counter.isClosed, isFalse);
      expect(name.isClosed, isFalse);
    });
  });
}
