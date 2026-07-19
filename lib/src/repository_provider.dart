import 'package:jaspr/jaspr.dart';

import 'provider_compat.dart';
import 'provider_inherited.dart';

/// Provides a repository or other dependency to descendant components.
class RepositoryProvider<T> extends StatefulComponent
    implements SingleChildComponent {
  /// Creates an owned repository.
  const RepositoryProvider({
    required T Function(BuildContext context) create,
    void Function(T value)? dispose,
    super.key,
    this.child,
    this.lazy,
  }) : _create = create,
       _dispose = dispose,
       _value = null;

  /// Provides an existing repository without disposing it.
  const RepositoryProvider.value({
    required T value,
    super.key,
    this.child,
  }) : _value = value,
       _create = null,
       _dispose = null,
       lazy = true;

  /// Component which can access the repository.
  final Component? child;

  /// Whether repository creation is lazy. A null value uses the Provider
  /// default of `true`, matching `flutter_bloc`.
  final bool? lazy;

  final T Function(BuildContext context)? _create;
  final void Function(T value)? _dispose;
  final T? _value;

  bool get _isValue => _create == null;

  /// Obtains the nearest repository of type [T].
  static T of<T>(BuildContext context, {bool listen = false}) {
    try {
      return listen
          ? ProviderInherited.watch<T>(context)
          : ProviderInherited.read<T>(context);
    } on ProviderNotFoundException catch (error) {
      if (error.valueType != T) rethrow;
      throw StateError(
        'RepositoryProvider.of() called with a context that does not contain '
        'a repository of type $T. No ancestor could be found from the '
        'supplied Component context.',
      );
    }
  }

  @override
  RepositoryProvider<T> copyWithChild(Component child) {
    if (_isValue) {
      return RepositoryProvider<T>.value(
        value: _value as T,
        key: key,
        child: child,
      );
    }
    return RepositoryProvider<T>(
      create: _create!,
      dispose: _dispose,
      key: key,
      lazy: lazy,
      child: child,
    );
  }

  @override
  State<RepositoryProvider<T>> createState() =>
      _RepositoryProviderState<T>();
}

class _RepositoryProviderState<T> extends State<RepositoryProvider<T>> {
  late ProviderController<T> _controller;
  late ProviderController<T?> _scopeController;
  int _version = 0;
  bool _ownsValue = false;

  @override
  void initState() {
    super.initState();
    _configureFrom(component);
  }

  void _configureFrom(RepositoryProvider<T> provider) {
    _ownsValue = !provider._isValue;
    if (provider._isValue) {
      _controller = ValueProviderController<T>(provider._value as T);
      _scopeController = NullableProviderController<T>(_controller);
    } else {
      _controller = LazyProviderController<T>(
        create: () => component._create!(context),
        onDispose: (value) => component._dispose?.call(value),
      );
      _scopeController = NullableProviderController<T>(_controller);
      if (!(provider.lazy ?? true)) {
        _controller.value;
      }
    }
  }

  void _disposeCurrent() {
    if (_ownsValue) _controller.dispose();
  }

  @override
  void didUpdateComponent(covariant RepositoryProvider<T> oldComponent) {
    super.didUpdateComponent(oldComponent);

    final oldWasValue = oldComponent._isValue;
    final newIsValue = component._isValue;

    if (oldWasValue && newIsValue) {
      final shouldNotify = component._value != oldComponent._value;
      final controller = _controller as ValueProviderController<T>;
      controller.updateValue(component._value as T);
      if (shouldNotify) _version++;
      return;
    }

    if (oldWasValue != newIsValue) {
      _disposeCurrent();
      _configureFrom(component);
      _version++;
      return;
    }

    if ((oldComponent.lazy ?? true) &&
        !(component.lazy ?? true) &&
        !_controller.hasValue) {
      _controller.value;
    }
  }

  @override
  void dispose() {
    _disposeCurrent();
    super.dispose();
  }

  @override
  Component build(BuildContext context) {
    assert(
      component.child != null,
      '${component.runtimeType} used outside of MultiRepositoryProvider must specify a child',
    );
    return ProviderInherited<T?>(
      controller: _scopeController,
      version: _version,
      child: component.child ?? const Component.empty(),
    );
  }
}
