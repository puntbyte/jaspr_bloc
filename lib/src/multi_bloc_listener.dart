import 'package:jaspr/jaspr.dart';

import 'bloc_listener_base.dart';

/// A Jaspr component that merges multiple [BlocListenerBase] components into
/// one widget tree.
///
/// [MultiBlocListener] improves readability and eliminates deep nesting of
/// multiple [BlocListener] components.
///
/// Instead of:
/// ```dart
/// BlocListener<BlocA, StateA>(
///   listener: (context, state) { /* ... */ },
///   child: BlocListener<BlocB, StateB>(
///     listener: (context, state) { /* ... */ },
///     child: MyPage(),
///   ),
/// )
/// ```
///
/// Use:
/// ```dart
/// MultiBlocListener(
///   listeners: [
///     BlocListener<BlocA, StateA>(listener: (context, state) { /* ... */ }),
///     BlocListener<BlocB, StateB>(listener: (context, state) { /* ... */ }),
///   ],
///   child: MyPage(),
/// )
/// ```
///
/// [MultiBlocListener] nests the listeners from left to right, so the first
/// listener in the list is the outermost ancestor in the component tree.
class MultiBlocListener extends StatelessComponent {
  /// The list of [BlocListenerBase] components to compose.
  ///
  /// Each listener should omit the [child] argument — [MultiBlocListener]
  /// assigns children automatically during composition.
  final List<BlocListenerBase> listeners;

  /// The single child component rendered inside all listeners.
  final Component child;

  /// Creates a [MultiBlocListener].
  ///
  /// [listeners] is required and must not be empty.
  /// [child] is the component placed at the innermost level of the tree.
  const MultiBlocListener({
    required this.listeners,
    required this.child,
    super.key,
  });

  @override
  Component build(BuildContext context) {
    return listeners.reversed.fold<Component>(
      child,
      (innerChild, listener) => listener.copyWithChild(innerChild),
    );
  }
}
