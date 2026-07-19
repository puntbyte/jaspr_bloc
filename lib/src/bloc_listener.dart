import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:jaspr/jaspr.dart';

import 'build_context_extensions.dart';
import 'jaspr_bloc_config.dart';
import 'provider_compat.dart';

/// Signature for the `listener` callback.
typedef BlocWidgetListener<S> = void Function(BuildContext context, S state);

/// Signature for the optional `listenWhen` callback.
typedef BlocListenerCondition<S> = bool Function(S previous, S current);

/// Invokes [listener] in response to state changes without rebuilding [child].
class BlocListener<B extends StateStreamable<S>, S> extends BlocListenerBase<B, S> {
  /// Creates a [BlocListener].
  const BlocListener({
    required super.listener,
    super.key,
    super.bloc,
    super.listenWhen,
    super.child,
  });
}

/// Base class for components which listen to a state stream.
abstract class BlocListenerBase<B extends StateStreamable<S>, S> extends StatefulComponent
    implements SingleChildComponent {
  /// Creates a [BlocListenerBase].
  const BlocListenerBase({
    required this.listener,
    super.key,
    this.bloc,
    this.child,
    this.listenWhen,
  });

  /// Descendant component. May be omitted in [MultiBlocListener].
  final Component? child;

  /// Explicit bloc, or null to look it up from context.
  final B? bloc;

  /// Callback invoked for accepted state changes.
  final BlocWidgetListener<S> listener;

  /// Optional state-change predicate.
  final BlocListenerCondition<S>? listenWhen;

  @override
  BlocListenerBase<B, S> copyWithChild(Component child) {
    return BlocListener<B, S>(
      key: key,
      bloc: bloc,
      listener: listener,
      listenWhen: listenWhen,
      child: child,
    );
  }

  @override
  State<BlocListenerBase<B, S>> createState() => _BlocListenerBaseState<B, S>();
}

class _BlocListenerBaseState<B extends StateStreamable<S>, S>
    extends State<BlocListenerBase<B, S>> {
  StreamSubscription<S>? _subscription;
  late B _bloc;
  late S _previousState;

  @override
  void initState() {
    super.initState();
    _bloc = component.bloc ?? context.read<B>();
    _previousState = _bloc.state;
    _subscribe();
  }

  @override
  void didUpdateComponent(covariant BlocListenerBase<B, S> oldComponent) {
    super.didUpdateComponent(oldComponent);
    final oldBloc = oldComponent.bloc ?? context.read<B>();
    final currentBloc = component.bloc ?? oldBloc;
    if (oldBloc != currentBloc) {
      _switchBloc(currentBloc);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bloc = component.bloc ?? context.read<B>();
    if (_bloc != bloc) {
      _switchBloc(bloc);
    }
  }

  void _switchBloc(B bloc) {
    _unsubscribe();
    _bloc = bloc;
    _previousState = bloc.state;
    _subscribe();
  }

  void _subscribe() {
    if (!isClientEnvironment) return;
    _subscription = _bloc.stream.listen((state) {
      if (!mounted) return;
      if (component.listenWhen?.call(_previousState, state) ?? true) {
        component.listener(context, state);
      }
      _previousState = state;
    });
  }

  void _unsubscribe() {
    unawaited(_subscription?.cancel() ?? Future<void>.value());
    _subscription = null;
  }

  @override
  void dispose() {
    _unsubscribe();
    super.dispose();
  }

  @override
  Component build(BuildContext context) {
    if (component.bloc == null) {
      context.select<B, bool>((bloc) => identical(_bloc, bloc));
    }
    return component.child ?? const Component.empty();
  }
}
