import 'package:jaspr/jaspr.dart';

import 'bloc_listener.dart';
import 'provider_compat.dart';

/// Merges multiple [BlocListener] components into one component tree.
class MultiBlocListener extends StatelessComponent {
  /// Creates a [MultiBlocListener].
  const MultiBlocListener({
    required this.listeners,
    required this.child,
    super.key,
  });

  /// Listeners to nest, with the first listener outermost.
  final List<SingleChildComponent> listeners;

  /// Innermost child.
  final Component child;

  @override
  Component build(BuildContext context) {
    return listeners.reversed.fold<Component>(
      child,
      (current, listener) => listener.copyWithChild(current),
    );
  }
}
