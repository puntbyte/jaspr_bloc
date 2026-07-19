import 'package:jaspr/jaspr.dart';

import 'provider_compat.dart';
import 'repository_provider.dart';

/// Merges multiple [RepositoryProvider] components into one component tree.
class MultiRepositoryProvider extends StatelessComponent {
  /// Creates a [MultiRepositoryProvider].
  const MultiRepositoryProvider({
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
