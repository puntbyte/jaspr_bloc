import 'package:bloc/bloc.dart';
import 'package:jaspr/jaspr.dart';

import 'bloc_builder.dart';
import 'bloc_listener.dart';
import 'build_context_extensions.dart';

/// Signature for selecting a derived value from state.
typedef BlocWidgetSelector<S, T> = T Function(S state);

/// Rebuilds only when the value selected from bloc state changes.
class BlocSelector<B extends StateStreamable<S>, S, T> extends StatefulComponent {
  /// Creates a [BlocSelector].
  const BlocSelector({required this.selector, required this.builder, super.key, this.bloc});

  /// Explicit bloc, or null to look it up from context.
  final B? bloc;

  /// Builder invoked with the selected value.
  final BlocWidgetBuilder<T> builder;

  /// Selects a value from the bloc state.
  final BlocWidgetSelector<S, T> selector;

  @override
  State<BlocSelector<B, S, T>> createState() => _BlocSelectorState<B, S, T>();
}

class _BlocSelectorState<B extends StateStreamable<S>, S, T> extends State<BlocSelector<B, S, T>> {
  late B _bloc;
  late T _state;

  @override
  void initState() {
    super.initState();
    _bloc = component.bloc ?? context.read<B>();
    _state = component.selector(_bloc.state);
  }

  @override
  void didUpdateComponent(covariant BlocSelector<B, S, T> oldComponent) {
    super.didUpdateComponent(oldComponent);
    final oldBloc = oldComponent.bloc ?? context.read<B>();
    final currentBloc = component.bloc ?? oldBloc;
    if (oldBloc != currentBloc) {
      _bloc = currentBloc;
      _state = component.selector(_bloc.state);
    } else if (oldComponent.selector != component.selector) {
      _state = component.selector(_bloc.state);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bloc = component.bloc ?? context.read<B>();
    if (_bloc != bloc) {
      _bloc = bloc;
      _state = component.selector(_bloc.state);
    }
  }

  @override
  Component build(BuildContext context) {
    if (component.bloc == null) {
      context.select<B, bool>((bloc) => identical(_bloc, bloc));
    }
    return BlocListener<B, S>(
      bloc: _bloc,
      listener: (context, state) {
        final selectedState = component.selector(state);
        if (_state != selectedState) {
          setState(() => _state = selectedState);
        }
      },
      child: component.builder(context, _state),
    );
  }
}
