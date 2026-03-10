import 'package:jaspr/jaspr.dart';

import 'repository_inherited.dart';

/// Signature for a function that creates a repository instance from a
/// `BuildContext`.
typedef RepositoryCreator<T> = T Function(BuildContext context);

/// A Jaspr component that provides a repository or service instance to its
/// descendants via dependency injection.
///
/// [RepositoryProvider] uses `InheritedComponent` to make any non-bloc
/// dependency (repositories, services, data sources) accessible to all
/// descendant components in the component tree.
///
/// Unlike [BlocProvider], [RepositoryProvider] does NOT manage any lifecycle
/// (no `.close()` call on dispose), since repositories are not `BlocBase`.
///
/// Use the default constructor when you want [RepositoryProvider] to create
/// the repository instance:
///
/// ```dart
/// RepositoryProvider<UserRepository>(
///   create: (context) => UserRepository(),
///   child: UserPage(),
/// )
/// ```
///
/// Use the [RepositoryProvider.value] constructor when you want to provide an
/// existing instance:
///
/// ```dart
/// RepositoryProvider.value(
///   value: existingRepository,
///   child: UserPage(),
/// )
/// ```
///
/// Descendants can access the repository using [RepositoryProvider.of]:
///
/// ```dart
/// final repo = RepositoryProvider.of<UserRepository>(context);
/// ```
class RepositoryProvider<T> extends StatefulComponent {
  final RepositoryCreator<T>? _create;
  final T? _value;
  final bool _isValueConstructor;

  /// The child component that will have access to the provided repository.
  ///
  /// Required when used as a standalone provider. When used inside
  /// [MultiRepositoryProvider], omit this — the child is provided
  /// automatically.
  final Component? child;

  /// Creates a [RepositoryProvider] that creates a repository instance.
  ///
  /// The [create] function is called once when the component is initialized.
  /// The repository is NOT closed when this component is disposed.
  ///
  /// When used standalone, [child] is required. When used inside
  /// [MultiRepositoryProvider], [child] may be omitted.
  const RepositoryProvider({
    required RepositoryCreator<T> create,
    this.child,
    super.key,
  }) : _create = create,
       _value = null,
       _isValueConstructor = false;

  /// Creates a [RepositoryProvider] that provides an existing [value].
  ///
  /// The provided instance is NOT closed when this component is disposed.
  /// Use this constructor when the repository's lifecycle is managed
  /// externally.
  ///
  /// When used standalone, [child] is required. When used inside
  /// [MultiRepositoryProvider], [child] may be omitted.
  const RepositoryProvider.value({required T value, this.child, super.key})
    : _value = value,
      _create = null,
      _isValueConstructor = true;

  /// Creates a copy of this provider with [child] as the child component.
  ///
  /// Used internally by [MultiRepositoryProvider] to compose a nested provider
  /// tree. Do not call this method directly.
  RepositoryProvider<T> copyWithChild(Component child) {
    if (_isValueConstructor) {
      return RepositoryProvider<T>.value(
        value: _value as T,
        child: child,
        key: key,
      );
    } else {
      return RepositoryProvider<T>(create: _create!, child: child, key: key);
    }
  }

  /// Retrieves the nearest [RepositoryProvider<T>] ancestor's repository from
  /// [context].
  ///
  /// Does not subscribe to changes. The calling component will not rebuild
  /// when the repository instance provided by [RepositoryProvider] changes.
  ///
  /// Throws an [AssertionError] if no [RepositoryProvider<T>] is found in the
  /// ancestor tree.
  static T of<T>(BuildContext context) {
    return RepositoryInherited.readOf<T>(context);
  }

  @override
  State<RepositoryProvider<T>> createState() => _RepositoryProviderState<T>();
}

class _RepositoryProviderState<T> extends State<RepositoryProvider<T>> {
  late T _repository;

  @override
  void initState() {
    super.initState();
    if (component._isValueConstructor) {
      _repository = component._value as T;
    } else {
      _repository = component._create!(context);
    }
  }

  @override
  Component build(BuildContext context) {
    assert(
      component.child != null,
      'RepositoryProvider requires a child component when used standalone. '
      'Provide a child argument or use RepositoryProvider inside '
      'MultiRepositoryProvider.',
    );
    return RepositoryInherited<T>(
      repository: _repository,
      child: component.child!,
    );
  }
}
