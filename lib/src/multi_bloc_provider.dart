import 'package:jaspr/jaspr.dart';

import 'bloc_provider.dart';
import 'provider_compat.dart';

/// Merges multiple [BlocProvider] components into one component tree.
class MultiBlocProvider extends StatelessComponent {
  /// Creates a [MultiBlocProvider].
  const MultiBlocProvider({
    required this.providers,
    required this.child,
    super.key,
  });

  /// Providers to nest, with the first provider outermost.
  final List<SingleChildComponent> providers;

  /// Innermost child.
  final Component child;

  @override
  Component build(BuildContext context) {
    return providers.reversed.fold<Component>(
      child,
      (current, provider) => provider.copyWithChild(current),
    );
  }
}
