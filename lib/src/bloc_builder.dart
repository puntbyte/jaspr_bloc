import 'package:bloc/bloc.dart';
import 'package:jaspr/jaspr.dart';

import 'bloc_provider.dart';
import 'bloc_subscription_mixin.dart';

/// Signature for a function that builds a `Component` from a `BuildContext`
/// and a state [S].
typedef BlocWidgetBuilder<S> =
    Component Function(BuildContext context, S state);

/// Signature for a function that determines whether [BlocBuilder] should
/// rebuild in response to a state change.
///
/// Return `true` to allow the rebuild, `false` to prevent it.
typedef BlocBuilderCondition<S> = bool Function(S previous, S current);

/// A Jaspr component that rebuilds its UI whenever a `BlocBase` emits a new
/// state.
///
/// [BlocBuilder] subscribes to the bloc's `Stream` in `initState` and calls
/// `setState` to trigger a rebuild when a new state is received. The [builder]
/// callback is invoked with the latest accepted state.
///
/// By default the nearest ancestor [BlocProvider] supplies the bloc. You may
/// override this by passing an explicit [bloc] parameter, which is useful when
/// you need to build against a bloc that is not in the ancestor tree.
///
/// Use [buildWhen] to prevent unnecessary rebuilds. When [buildWhen] returns
/// `false` for a state transition the component keeps displaying the last
/// accepted state.
///
/// ```dart
/// BlocBuilder<CounterCubit, int>(
///   buildWhen: (previous, current) => current != previous,
///   builder: (context, count) {
///     return span([Component.text('Count: $count')]);
///   },
/// )
/// ```
class BlocBuilder<B extends BlocBase<S>, S> extends StatefulComponent {
  /// Creates a [BlocBuilder].
  ///
  /// The [builder] callback is required and is called with the `BuildContext`
  /// and the current state whenever a rebuild is needed.
  ///
  /// If [bloc] is omitted the nearest ancestor [BlocProvider<B>] is used.
  ///
  /// The optional [buildWhen] predicate receives the previous and current
  /// state and must return `true` to allow the rebuild.
  const BlocBuilder({
    required this.builder,
    this.bloc,
    this.buildWhen,
    super.key,
  });

  /// An optional explicit bloc instance.
  ///
  /// When non-null, this bloc is used instead of the nearest ancestor
  /// [BlocProvider<B>].
  final B? bloc;

  /// Called every time the component needs to rebuild.
  ///
  /// Receives the `BuildContext` and the current accepted state.
  final BlocWidgetBuilder<S> builder;

  /// An optional predicate that controls whether a state change triggers a
  /// rebuild.
  ///
  /// When omitted every state emission causes a rebuild. When provided, a
  /// rebuild only occurs when this function returns `true`.
  final BlocBuilderCondition<S>? buildWhen;

  @override
  State<BlocBuilder<B, S>> createState() => _BlocBuilderState<B, S>();
}

class _BlocBuilderState<B extends BlocBase<S>, S>
    extends State<BlocBuilder<B, S>>
    with BlocSubscriptionMixin<BlocBuilder<B, S>> {
  late B _bloc;
  late S _state;

  @override
  void initState() {
    super.initState();
    _bloc = component.bloc ?? BlocProvider.of<B>(context);
    _state = _bloc.state;
    subscribeTo<B, S>(
      _bloc,
      onState: (state) {
        setState(() {
          _state = state;
        });
      },
      filter: component.buildWhen,
    );
  }

  @override
  Component build(BuildContext context) {
    return component.builder(context, _state);
  }
}
