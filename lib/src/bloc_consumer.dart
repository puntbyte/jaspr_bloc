import 'package:bloc/bloc.dart';
import 'package:jaspr/jaspr.dart';

import 'bloc_builder.dart';
import 'bloc_listener.dart';
import 'build_context_extensions.dart';

/// Combines [BlocBuilder] and [BlocListener].
class BlocConsumer<B extends StateStreamable<S>, S>
    extends StatefulComponent {
  /// Creates a [BlocConsumer].
  const BlocConsumer({
    required this.builder,
    required this.listener,
    super.key,
    this.bloc,
    this.buildWhen,
    this.listenWhen,
  });

  /// Explicit bloc, or null to look it up from context.
  final B? bloc;

  /// Builder invoked for accepted states.
  final BlocWidgetBuilder<S> builder;

  /// Listener invoked for accepted states.
  final BlocWidgetListener<S> listener;

  /// Optional builder predicate.
  final BlocBuilderCondition<S>? buildWhen;

  /// Optional listener predicate.
  final BlocListenerCondition<S>? listenWhen;

  @override
  State<BlocConsumer<B, S>> createState() => _BlocConsumerState<B, S>();
}

class _BlocConsumerState<B extends StateStreamable<S>, S>
    extends State<BlocConsumer<B, S>> {
  late B _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = component.bloc ?? context.read<B>();
  }

  @override
  void didUpdateComponent(covariant BlocConsumer<B, S> oldComponent) {
    super.didUpdateComponent(oldComponent);
    final oldBloc = oldComponent.bloc ?? context.read<B>();
    final currentBloc = component.bloc ?? oldBloc;
    if (oldBloc != currentBloc) _bloc = currentBloc;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bloc = component.bloc ?? context.read<B>();
    if (_bloc != bloc) _bloc = bloc;
  }

  @override
  Component build(BuildContext context) {
    if (component.bloc == null) {
      context.select<B, bool>((bloc) => identical(_bloc, bloc));
    }
    return BlocBuilder<B, S>(
      bloc: _bloc,
      builder: component.builder,
      buildWhen: (previous, current) {
        if (component.listenWhen?.call(previous, current) ?? true) {
          component.listener(context, current);
        }
        return component.buildWhen?.call(previous, current) ?? true;
      },
    );
  }
}
