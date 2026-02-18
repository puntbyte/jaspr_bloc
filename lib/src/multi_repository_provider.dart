import 'package:jaspr/jaspr.dart';

import 'repository_provider.dart';

/// A Jaspr component that merges multiple [RepositoryProvider] components into
/// one widget tree.
///
/// [MultiRepositoryProvider] improves the readability and eliminates the need
/// to deeply nest multiple [RepositoryProvider] components.
///
/// Instead of:
/// ```dart
/// RepositoryProvider<UserRepository>(
///   create: (_) => UserRepository(),
///   child: RepositoryProvider<AuthRepository>(
///     create: (_) => AuthRepository(),
///     child: MyPage(),
///   ),
/// )
/// ```
///
/// Use:
/// ```dart
/// MultiRepositoryProvider(
///   providers: [
///     RepositoryProvider<UserRepository>(create: (_) => UserRepository()),
///     RepositoryProvider<AuthRepository>(create: (_) => AuthRepository()),
///   ],
///   child: MyPage(),
/// )
/// ```
///
/// [MultiRepositoryProvider] nests the providers from left to right, so the
/// first provider in the list is the outermost ancestor in the component tree.
class MultiRepositoryProvider extends StatelessComponent {
  /// The list of [RepositoryProvider] components to nest.
  ///
  /// Each provider in the list should omit the [child] argument —
  /// [MultiRepositoryProvider] assigns children automatically during
  /// composition.
  final List<RepositoryProvider<Object?>> providers;

  /// The child component that has access to all provided repositories.
  final Component child;

  /// Creates a [MultiRepositoryProvider].
  ///
  /// [providers] is required and must not be empty.
  /// [child] is the component placed at the innermost level of the tree.
  const MultiRepositoryProvider({
    required this.providers,
    required this.child,
    super.key,
  });

  @override
  Component build(BuildContext context) {
    return providers.reversed.fold<Component>(
      child,
      (innerChild, provider) => provider.copyWithChild(innerChild),
    );
  }
}
