import 'package:bloc/bloc.dart';
import 'package:jaspr/jaspr.dart';

/// Internal [InheritedComponent] that holds a [BlocBase] instance.
///
/// This component is used internally by [BlocProvider] to provide bloc
/// instances down the component tree using Jaspr's dependency mechanism.
///
/// This class is not exported in the public API and should not be used
/// directly by consumers of the jaspr_bloc package.
class BlocInherited<T extends BlocBase<Object?>> extends InheritedComponent {
  /// The bloc instance provided to descendant components.
  final T bloc;

  /// A version counter that increments each time the bloc emits a new state.
  ///
  /// Managed by [BlocProvider]. When this value changes,
  /// [updateShouldNotify] returns `true`, causing all components that
  /// subscribed via [of] to rebuild. This enables [context.watch] semantics.
  final int stateVersion;

  /// Creates a [BlocInherited] component.
  ///
  /// The [bloc] parameter is required and holds the bloc instance.
  /// The [stateVersion] parameter is required and must be incremented by
  /// [BlocProvider] each time the bloc emits a new state.
  /// The [child] parameter is required and represents the descendant tree.
  const BlocInherited({
    required this.bloc,
    required this.stateVersion,
    required super.child,
    super.key,
  });

  /// Retrieves the nearest [BlocInherited] ancestor of type [T] from the
  /// component tree, subscribing to rebuild notifications.
  ///
  /// This method uses [dependOnInheritedComponentOfExactType] to look up
  /// the bloc and registers the caller as a dependent so it rebuilds when
  /// the bloc instance changes.
  ///
  /// The [context] parameter is the build context from which to start the
  /// lookup.
  ///
  /// Returns the bloc instance of type [T].
  ///
  /// Throws an [AssertionError] if no [BlocInherited<T>] is found in the
  /// component tree.
  static T of<T extends BlocBase<Object?>>(BuildContext context) {
    final inherited = context
        .dependOnInheritedComponentOfExactType<BlocInherited<T>>();
    assert(inherited != null, 'No BlocProvider<$T> found in context');
    return inherited!.bloc;
  }

  /// Retrieves the nearest [BlocInherited] ancestor of type [T] from the
  /// component tree without subscribing to rebuild notifications.
  ///
  /// This method uses [getElementForInheritedComponentOfExactType] to look
  /// up the bloc without registering the caller as a dependent. The calling
  /// component will NOT rebuild when the bloc instance changes.
  ///
  /// The [context] parameter is the build context from which to start the
  /// lookup.
  ///
  /// Returns the bloc instance of type [T].
  ///
  /// Throws an [AssertionError] if no [BlocInherited<T>] is found in the
  /// component tree.
  static T readOf<T extends BlocBase<Object?>>(BuildContext context) {
    final element = context
        .getElementForInheritedComponentOfExactType<BlocInherited<T>>();
    assert(element != null, 'No BlocProvider<$T> found in context');
    return (element!.component as BlocInherited<T>).bloc;
  }

  @override
  bool updateShouldNotify(covariant BlocInherited<T> oldComponent) {
    return bloc != oldComponent.bloc ||
        stateVersion != oldComponent.stateVersion;
  }
}
