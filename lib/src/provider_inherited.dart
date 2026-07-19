import 'package:collection/collection.dart';
import 'package:jaspr/jaspr.dart';

import 'provider_compat.dart';

/// Internal controller used by providers to support lazy creation.
abstract class ProviderController<T> {
  /// Whether the value has already been created/accessed.
  bool get hasValue;

  /// The provided value, creating it lazily when required.
  T get value;

  /// Releases any owned value.
  void dispose();
}

/// Stable nullable view over a provider controller.
///
/// Flutter Provider keys its inherited scope with `T?` even when the public
/// provider is declared with a non-nullable `T`. This adapter gives Jaspr the
/// same lookup behavior, including `context.read<T?>()` finding Provider<T>.
class NullableProviderController<T> implements ProviderController<T?> {
  /// Creates a nullable view over [delegate].
  NullableProviderController(this.delegate);

  /// The underlying provider controller.
  final ProviderController<T> delegate;

  @override
  bool get hasValue => delegate.hasValue;

  @override
  T? get value => delegate.value;

  @override
  void dispose() => delegate.dispose();
}

/// Controller for an externally-owned value.
class ValueProviderController<T> implements ProviderController<T> {
  /// Creates a value controller.
  ValueProviderController(this._value, {void Function(T value)? onFirstAccess})
    : _onFirstAccess = onFirstAccess;

  T _value;
  final void Function(T value)? _onFirstAccess;
  bool _accessed = false;

  @override
  bool get hasValue => true;

  @override
  T get value {
    if (!_accessed) {
      _accessed = true;
      _onFirstAccess?.call(_value);
    }
    return _value;
  }

  /// Updates the externally-owned value.
  void updateValue(T value, {bool restartListening = false}) {
    _value = value;
    if (restartListening) _accessed = false;
  }

  @override
  void dispose() {}
}

/// Controller for a lazily-created, provider-owned value.
class LazyProviderController<T> implements ProviderController<T> {
  /// Creates a lazy controller.
  LazyProviderController({
    required T Function() create,
    void Function(T value)? onCreate,
    void Function(T value)? onDispose,
  }) : _create = create,
       _onCreate = onCreate,
       _onDispose = onDispose;

  final T Function() _create;
  final void Function(T value)? _onCreate;
  final void Function(T value)? _onDispose;

  T? _value;
  bool _hasValue = false;
  bool _disposed = false;

  @override
  bool get hasValue => _hasValue;

  @override
  T get value {
    if (_disposed) {
      throw StateError('Tried to read a disposed provider value.');
    }
    if (!_hasValue) {
      final value = _create();
      _value = value;
      _hasValue = true;
      _onCreate?.call(value);
    }
    return _value as T;
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    if (_hasValue) {
      _onDispose?.call(_value as T);
    }
    _value = null;
  }
}

/// Internal inherited component shared by bloc and repository providers.
///
/// The generic argument is nullable by design, matching Provider's internal
/// `_InheritedProviderScope<T?>` lookup model.
class ProviderInherited<T> extends InheritedComponent {
  /// Creates a provider inherited component.
  const ProviderInherited({
    required this.controller,
    required this.version,
    required super.child,
    super.key,
  });

  /// Controller which owns or references the current value.
  final ProviderController<T> controller;

  /// Revision incremented whenever dependents may need to be notified.
  final int version;

  /// Reads the current value.
  T get value => controller.value;

  @override
  ProviderInheritedElement<T> createElement() =>
      ProviderInheritedElement<T>(this);

  /// Reads a provider without registering a dependency.
  static T read<T>(BuildContext context) {
    final element = context
        .getElementForInheritedComponentOfExactType<ProviderInherited<T?>>();
    if (element == null) {
      if (null is T) return null as T;
      throw ProviderNotFoundException(T, context.component.runtimeType);
    }
    return _requireValue<T>(
      (element.component as ProviderInherited<T?>).value,
      context,
    );
  }

  /// Reads a provider and registers an unconditional dependency.
  static T watch<T>(BuildContext context) {
    final inherited = context
        .dependOnInheritedComponentOfExactType<ProviderInherited<T?>>();
    if (inherited == null) {
      if (null is T) return null as T;
      throw ProviderNotFoundException(T, context.component.runtimeType);
    }
    return _requireValue<T>(inherited.value, context);
  }

  /// Reads a selected value and only rebuilds the dependent when that result
  /// changes according to Provider's deep-collection equality.
  static R select<T, R>(
    BuildContext context,
    R Function(T value) selector,
  ) {
    assert(
      context.debugDoingBuild,
      'Tried to use `context.select` outside the build method of a component.',
    );

    final element = context
        .getElementForInheritedComponentOfExactType<ProviderInherited<T?>>();
    final T value;
    if (element == null) {
      if (null is! T) {
        throw ProviderNotFoundException(T, context.component.runtimeType);
      }
      value = null as T;
    } else {
      value = _requireValue<T>(
        (element.component as ProviderInherited<T?>).value,
        context,
      );
    }

    final selected = selector(value);
    if (element != null) {
      final aspect = ProviderSelectorAspect<T?, R>(
        (rawValue) => selector(_requireValue<T>(rawValue, context)),
        selected,
      );
      context.dependOnInheritedElement(element, aspect: aspect);
    } else {
      // Register an unsatisfied inherited dependency so a moved/reparented
      // component can discover a provider later, matching Provider behavior.
      context.dependOnInheritedComponentOfExactType<ProviderInherited<T?>>();
    }
    return selected;
  }

  static T _requireValue<T>(T? value, BuildContext context) {
    if (value is! T) {
      throw ProviderNullException(T, context.component.runtimeType);
    }
    return value;
  }

  @override
  bool updateShouldNotify(covariant ProviderInherited<T> oldComponent) {
    return !identical(controller, oldComponent.controller) ||
        version != oldComponent.version;
  }
}

/// Selector registration used by [ProviderInheritedElement].
abstract class ProviderSelectorAspectBase<T> {
  /// Re-evaluates the selector and returns whether its result changed.
  bool update(T value);
}

/// Typed selector registration.
class ProviderSelectorAspect<T, R>
    implements ProviderSelectorAspectBase<T> {
  /// Creates a selector registration with its initial value.
  ProviderSelectorAspect(this.selector, this.selected);

  static const DeepCollectionEquality _equality = DeepCollectionEquality();

  /// Selector callback.
  final R Function(T value) selector;

  /// Most recently selected value.
  R selected;

  @override
  bool update(T value) {
    final next = selector(value);
    if (_equality.equals(selected, next)) return false;
    selected = next;
    return true;
  }
}

class _ProviderDependency<T> {
  bool registering = false;
  bool active = false;
  bool unconditional = false;
  bool pendingUnconditional = false;

  List<ProviderSelectorAspectBase<T>> selectors =
      <ProviderSelectorAspectBase<T>>[];
  final List<ProviderSelectorAspectBase<T>> pendingSelectors =
      <ProviderSelectorAspectBase<T>>[];

  void beginRegistration() {
    if (registering) return;
    registering = true;
    pendingUnconditional = false;
    pendingSelectors.clear();
  }

  void register(Object? aspect) {
    beginRegistration();
    if (aspect is ProviderSelectorAspectBase<T>) {
      pendingSelectors.add(aspect);
    } else {
      pendingUnconditional = true;
    }
  }

  void finishBuild() {
    if (registering) {
      active = true;
      unconditional = pendingUnconditional;
      selectors = List<ProviderSelectorAspectBase<T>>.of(pendingSelectors);
      registering = false;
      pendingUnconditional = false;
      pendingSelectors.clear();
    } else {
      active = false;
      unconditional = false;
      selectors = <ProviderSelectorAspectBase<T>>[];
    }
  }
}

/// Custom inherited element which implements Provider-style `select`
/// filtering and dynamically replaces selector dependencies every build.
class ProviderInheritedElement<T> extends InheritedElement {
  /// Creates an element for [component].
  ProviderInheritedElement(ProviderInherited<T> component) : super(component);

  @override
  void updateDependencies(Element dependent, Object? aspect) {
    final dependency =
        (getDependencies(dependent) as _ProviderDependency<T>?) ??
        _ProviderDependency<T>();
    dependency.register(aspect);
    setDependencies(dependent, dependency);
  }

  @override
  void notifyDependent(
    covariant ProviderInherited<T> oldComponent,
    Element dependent,
  ) {
    final dependency = getDependencies(dependent) as _ProviderDependency<T>?;
    if (dependency == null || !dependency.active) return;

    if (dependency.unconditional) {
      dependent.didChangeDependencies();
      return;
    }

    final value = (component as ProviderInherited<T>).value;
    var changed = false;
    for (final selector in dependency.selectors) {
      changed = selector.update(value) || changed;
    }
    if (changed) dependent.didChangeDependencies();
  }

  @override
  void didRebuildDependent(Element dependent) {
    final dependency = getDependencies(dependent) as _ProviderDependency<T>?;
    dependency?.finishBuild();
    super.didRebuildDependent(dependent);
  }
}
