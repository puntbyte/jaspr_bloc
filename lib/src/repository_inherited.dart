import 'package:jaspr/jaspr.dart';

/// Internal [InheritedComponent] that holds a repository instance of type [T].
///
/// This component is used internally by [RepositoryProvider] to provide
/// repository instances down the component tree using Jaspr's dependency
/// mechanism.
///
/// This class is not exported in the public API and should not be used
/// directly by consumers of the jaspr_bloc package.
class RepositoryInherited<T> extends InheritedComponent {
  /// The repository instance provided to descendant components.
  final T repository;

  /// Creates a [RepositoryInherited] component.
  ///
  /// The [repository] parameter is required and holds the repository instance.
  /// The [child] parameter is required and represents the descendant tree.
  const RepositoryInherited({
    required this.repository,
    required super.child,
    super.key,
  });

  /// Retrieves the nearest [RepositoryInherited] ancestor of type [T] from the
  /// component tree, subscribing to rebuild notifications.
  ///
  /// The [context] parameter is the build context from which to start the
  /// lookup.
  ///
  /// Throws an [AssertionError] if no [RepositoryInherited<T>] is found in the
  /// component tree.
  static T of<T>(BuildContext context) {
    final inherited = context
        .dependOnInheritedComponentOfExactType<RepositoryInherited<T>>();
    assert(inherited != null, 'No RepositoryProvider<$T> found in context');
    return inherited!.repository;
  }

  /// Retrieves the nearest [RepositoryInherited] ancestor of type [T] from the
  /// component tree without subscribing to rebuild notifications.
  ///
  /// The calling component will NOT rebuild when the repository instance
  /// changes.
  ///
  /// The [context] parameter is the build context from which to start the
  /// lookup.
  ///
  /// Throws an [AssertionError] if no [RepositoryInherited<T>] is found in the
  /// component tree.
  static T readOf<T>(BuildContext context) {
    final element = context
        .getElementForInheritedComponentOfExactType<RepositoryInherited<T>>();
    assert(element != null, 'No RepositoryProvider<$T> found in context');
    return (element!.component as RepositoryInherited<T>).repository;
  }

  @override
  bool updateShouldNotify(covariant RepositoryInherited<T> oldComponent) {
    return repository != oldComponent.repository;
  }
}
