import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:jaspr/jaspr.dart';

import 'jaspr_bloc_config.dart';
import 'provider_compat.dart';
import 'provider_inherited.dart';

/// Provides a [Bloc] or [Cubit] to descendant components.
///
/// The public constructor surface mirrors `flutter_bloc`'s `BlocProvider`,
/// with Jaspr [Component]s replacing Flutter widgets.
class BlocProvider<T extends StateStreamableSource<Object?>>
    extends StatefulComponent
    implements SingleChildComponent {
  /// Creates and owns a bloc instance.
  const BlocProvider({
    required T Function(BuildContext context) create,
    super.key,
    this.child,
    this.lazy = true,
  }) : _create = create,
       _value = null;

  /// Provides an existing bloc instance without closing it.
  const BlocProvider.value({
    required T value,
    super.key,
    this.child,
  }) : _value = value,
       _create = null,
       lazy = true;

  /// Component which can access the provided bloc.
  final Component? child;

  /// Whether creation/listening should be deferred until first access.
  final bool lazy;

  final T Function(BuildContext context)? _create;
  final T? _value;

  bool get _isValue => _create == null;

  /// Obtains the nearest bloc of type [T].
  static T of<T extends StateStreamableSource<Object?>>(
    BuildContext context, {
    bool listen = false,
  }) {
    try {
      return listen
          ? ProviderInherited.watch<T>(context)
          : ProviderInherited.read<T>(context);
    } on ProviderNotFoundException catch (error) {
      if (error.valueType != T) rethrow;
      throw StateError(
        'BlocProvider.of() called with a context that does not contain a $T. '
        'No ancestor could be found from the supplied Component context.',
      );
    }
  }

  @override
  BlocProvider<T> copyWithChild(Component child) {
    if (_isValue) {
      return BlocProvider<T>.value(value: _value as T, key: key, child: child);
    }
    return BlocProvider<T>(
      create: _create!,
      key: key,
      lazy: lazy,
      child: child,
    );
  }

  @override
  State<BlocProvider<T>> createState() => _BlocProviderState<T>();
}

class _BlocProviderState<T extends StateStreamableSource<Object?>>
    extends State<BlocProvider<T>> {
  late ProviderController<T> _controller;
  late ProviderController<T?> _scopeController;
  StreamSubscription<Object?>? _subscription;
  int _version = 0;
  bool _ownsValue = false;

  @override
  void initState() {
    super.initState();
    _configureFrom(component);
  }

  void _configureFrom(BlocProvider<T> provider) {
    _ownsValue = !provider._isValue;
    if (provider._isValue) {
      _controller = ValueProviderController<T>(
        provider._value as T,
        onFirstAccess: _startListening,
      );
      _scopeController = NullableProviderController<T>(_controller);
    } else {
      _controller = LazyProviderController<T>(
        create: () => component._create!(context),
        onCreate: _startListening,
        onDispose: (bloc) => unawaited(Future<void>.sync(bloc.close)),
      );
      _scopeController = NullableProviderController<T>(_controller);
      if (!provider.lazy) {
        _controller.value;
      }
    }
  }

  void _startListening(T bloc) {
    if (!isClientEnvironment || _subscription != null) return;
    _subscription = bloc.stream.listen((_) {
      if (!mounted) return;
      setState(() => _version++);
    });
  }

  void _disposeCurrent() {
    unawaited(_subscription?.cancel() ?? Future<void>.value());
    _subscription = null;
    if (_ownsValue) {
      _controller.dispose();
    }
  }

  @override
  void didUpdateComponent(covariant BlocProvider<T> oldComponent) {
    super.didUpdateComponent(oldComponent);

    final oldWasValue = oldComponent._isValue;
    final newIsValue = component._isValue;

    if (oldWasValue && newIsValue) {
      final shouldNotify = component._value != oldComponent._value;
      final controller = _controller as ValueProviderController<T>;
      if (shouldNotify) {
        unawaited(_subscription?.cancel() ?? Future<void>.value());
        _subscription = null;
      }
      controller.updateValue(
        component._value as T,
        restartListening: shouldNotify,
      );
      if (shouldNotify) _version++;
      return;
    }

    if (oldWasValue != newIsValue) {
      _disposeCurrent();
      _configureFrom(component);
      _version++;
      return;
    }

    // Provider-owned values are preserved when the parent rebuilds, just like
    // Flutter Provider. A lazy provider is eagerly initialized if `lazy`
    // changes from true to false before first access.
    if (oldComponent.lazy && !component.lazy && !_controller.hasValue) {
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
      '${component.runtimeType} used outside of MultiBlocProvider must specify a child',
    );
    return ProviderInherited<T?>(
      controller: _scopeController,
      version: _version,
      child: component.child ?? const Component.empty(),
    );
  }
}
