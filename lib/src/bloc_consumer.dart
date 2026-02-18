import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:jaspr/jaspr.dart';

import 'bloc_builder.dart';
import 'bloc_listener.dart';
import 'bloc_provider.dart';

/// A Jaspr component that combines [BlocBuilder] and [BlocListener] into a
/// single component backed by a **single** stream subscription.
///
/// Use [BlocConsumer] when you need both to rebuild the UI and to execute side
/// effects in response to bloc state changes. It is equivalent to nesting a
/// [BlocListener] inside a [BlocBuilder], but more efficient because only one
/// subscription to the bloc's [Stream] is created.
///
/// Both [builder] and [listener] are required. The [buildWhen] and
/// [listenWhen] predicates are independent — each gate only their respective
/// callback.
///
/// By default the nearest ancestor [BlocProvider] supplies the bloc. You may
/// override this by passing an explicit [bloc] parameter.
///
/// ```dart
/// BlocConsumer<CounterCubit, int>(
///   listenWhen: (previous, current) => current == 10,
///   listener: (context, state) {
///     // Show a toast when state reaches 10.
///   },
///   buildWhen: (previous, current) => current % 2 == 0,
///   builder: (context, count) {
///     return span([Component.text('Even count: $count')]);
///   },
/// )
/// ```
class BlocConsumer<B extends BlocBase<S>, S> extends StatefulComponent {
  /// Creates a [BlocConsumer].
  ///
  /// Both [builder] and [listener] are required.
  ///
  /// If [bloc] is omitted the nearest ancestor [BlocProvider<B>] is used.
  ///
  /// The optional [buildWhen] predicate controls rebuilds; [listenWhen]
  /// controls listener invocations. Each predicate receives the previous and
  /// current state and must return `true` to allow the action.
  const BlocConsumer({
    required this.builder,
    required this.listener,
    this.bloc,
    this.buildWhen,
    this.listenWhen,
    super.key,
  });

  /// An optional explicit bloc instance.
  ///
  /// When non-null, this bloc is used instead of the nearest ancestor
  /// [BlocProvider<B>].
  final B? bloc;

  /// Called every time the component needs to rebuild.
  ///
  /// Receives the [BuildContext] and the current accepted state.
  final BlocWidgetBuilder<S> builder;

  /// An optional predicate that controls whether a state change triggers a
  /// rebuild.
  ///
  /// When omitted every state emission causes a rebuild. When provided, a
  /// rebuild only occurs when this function returns `true`.
  final BlocBuilderCondition<S>? buildWhen;

  /// Called on each state change that passes [listenWhen].
  ///
  /// Receives the [BuildContext] and the new state. Use this callback to
  /// trigger side effects such as navigation or notifications.
  final BlocWidgetListener<S> listener;

  /// An optional predicate that controls whether [listener] is called for a
  /// given state transition.
  ///
  /// When omitted [listener] is called for every state emission. When
  /// provided, [listener] is only called when this function returns `true`.
  final BlocListenerCondition<S>? listenWhen;

  @override
  State<BlocConsumer<B, S>> createState() => _BlocConsumerState<B, S>();
}

class _BlocConsumerState<B extends BlocBase<S>, S>
    extends State<BlocConsumer<B, S>> {
  StreamSubscription<S>? _subscription;
  late S _state;
  late S _previous;

  @override
  void initState() {
    super.initState();
    final B bloc = component.bloc ?? BlocProvider.of<B>(context);
    _state = bloc.state;
    _previous = bloc.state;
    _subscription = bloc.stream.listen(_onState);
  }

  void _onState(S state) {
    if (component.listenWhen == null ||
        component.listenWhen!(_previous, state)) {
      component.listener(context, state);
    }
    if (component.buildWhen == null || component.buildWhen!(_previous, state)) {
      setState(() {
        _state = state;
      });
    }
    _previous = state;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Component build(BuildContext context) {
    return component.builder(context, _state);
  }
}
