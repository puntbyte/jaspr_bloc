import 'package:bloc/bloc.dart';
import 'package:jaspr/jaspr.dart';

import 'bloc_listener.dart';
import 'build_context_extensions.dart';

/// Signature for a component builder based on bloc state.
typedef BlocWidgetBuilder<S> =
    Component Function(BuildContext context, S state);

/// Signature for the optional `buildWhen` callback.
typedef BlocBuilderCondition<S> = bool Function(S previous, S current);

/// Rebuilds in response to new bloc states.
class BlocBuilder<B extends StateStreamable<S>, S>
    extends BlocBuilderBase<B, S> {
  /// Creates a [BlocBuilder].
  const BlocBuilder({
    required this.builder,
    super.key,
    B? bloc,
    BlocBuilderCondition<S>? buildWhen,
  }) : super(bloc: bloc, buildWhen: buildWhen);

  /// Builder invoked with the current accepted state.
  final BlocWidgetBuilder<S> builder;

  @override
  Component build(BuildContext context, S state) => builder(context, state);
}

/// Base class for components which build from a bloc state.
abstract class BlocBuilderBase<B extends StateStreamable<S>, S>
    extends StatefulComponent {
  /// Creates a [BlocBuilderBase].
  const BlocBuilderBase({super.key, this.bloc, this.buildWhen});

  /// Explicit bloc, or null to look it up from context.
  final B? bloc;

  /// Optional rebuild predicate.
  final BlocBuilderCondition<S>? buildWhen;

  /// Returns a component for [state].
  Component build(BuildContext context, S state);

  @override
  State<BlocBuilderBase<B, S>> createState() =>
      _BlocBuilderBaseState<B, S>();
}

class _BlocBuilderBaseState<B extends StateStreamable<S>, S>
    extends State<BlocBuilderBase<B, S>> {
  late B _bloc;
  late S _state;

  @override
  void initState() {
    super.initState();
    _bloc = component.bloc ?? context.read<B>();
    _state = _bloc.state;
  }

  @override
  void didUpdateComponent(covariant BlocBuilderBase<B, S> oldComponent) {
    super.didUpdateComponent(oldComponent);
    final oldBloc = oldComponent.bloc ?? context.read<B>();
    final currentBloc = component.bloc ?? oldBloc;
    if (oldBloc != currentBloc) {
      _bloc = currentBloc;
      _state = _bloc.state;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bloc = component.bloc ?? context.read<B>();
    if (_bloc != bloc) {
      _bloc = bloc;
      _state = _bloc.state;
    }
  }

  @override
  Component build(BuildContext context) {
    if (component.bloc == null) {
      context.select<B, bool>((bloc) => identical(_bloc, bloc));
    }
    return BlocListener<B, S>(
      bloc: _bloc,
      listenWhen: component.buildWhen,
      listener: (context, state) => setState(() => _state = state),
      child: component.build(context, _state),
    );
  }
}
