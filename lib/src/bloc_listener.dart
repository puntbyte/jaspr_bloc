import 'package:bloc/bloc.dart';
import 'package:jaspr/jaspr.dart';

import 'bloc_listener_base.dart';
import 'bloc_provider.dart';
import 'bloc_subscription_mixin.dart';

/// Signature for a listener callback that reacts to state changes without
/// causing a UI rebuild.
typedef BlocWidgetListener<S> = void Function(BuildContext context, S state);

/// Signature for a function that determines whether [BlocListener] should
/// invoke its [BlocWidgetListener] in response to a state change.
///
/// Return `true` to invoke the listener, `false` to suppress it.
typedef BlocListenerCondition<S> = bool Function(S previous, S current);

/// A Jaspr component that invokes a [listener] callback on bloc state changes
/// without rebuilding its [child].
///
/// [BlocListener] subscribes to the bloc's [Stream] in `initState`. On each
/// new state (filtered by the optional [listenWhen] predicate) the [listener]
/// is called with the current `BuildContext` and the new state.
///
/// The [listener] is **not** called for the bloc's initial state — only for
/// subsequent emissions.
///
/// The [child] component is rendered as-is and is never rebuilt due to state
/// changes. This makes [BlocListener] ideal for side effects such as
/// navigation, showing snackbars, or triggering analytics events.
///
/// By default the nearest ancestor [BlocProvider] supplies the bloc. You may
/// override this by passing an explicit [bloc] parameter.
///
/// ```dart
/// BlocListener<AuthBloc, AuthState>(
///   listenWhen: (previous, current) => current is AuthFailure,
///   listener: (context, state) {
///     // Navigate to error page, show toast, etc.
///   },
///   child: LoginForm(),
/// )
/// ```
class BlocListener<B extends BlocBase<S>, S> extends BlocListenerBase {
  /// Creates a [BlocListener].
  ///
  /// Both [listener] and [child] are required.
  ///
  /// If [bloc] is omitted the nearest ancestor [BlocProvider] is used.
  ///
  /// The optional [listenWhen] predicate receives the previous and current
  /// state and must return `true` for the [listener] to be called.
  const BlocListener({
    required this.listener,
    required this.child,
    this.bloc,
    this.listenWhen,
    super.key,
  });

  /// An optional explicit bloc instance.
  ///
  /// When non-null, this bloc is used instead of the nearest ancestor
  /// [BlocProvider<B>].
  final B? bloc;

  /// The child component rendered by this [BlocListener].
  ///
  /// The child is never rebuilt due to state changes.
  final Component child;

  /// Called on each state change that passes [listenWhen].
  ///
  /// Receives the `BuildContext` and the new state. Use this callback to
  /// trigger side effects such as navigation or notifications.
  final BlocWidgetListener<S> listener;

  /// An optional predicate that controls whether [listener] is called for a
  /// given state transition.
  ///
  /// When omitted [listener] is called for every state emission. When
  /// provided, [listener] is only called when this function returns `true`.
  final BlocListenerCondition<S>? listenWhen;

  /// Creates a copy of this listener with [child] as the child component.
  ///
  /// Used internally by [MultiBlocListener] to compose a nested listener tree.
  /// Do not call this method directly.
  @override
  BlocListener<B, S> copyWithChild(Component child) {
    return BlocListener<B, S>(
      listener: listener,
      child: child,
      bloc: bloc,
      listenWhen: listenWhen,
      key: key,
    );
  }

  @override
  State<BlocListener<B, S>> createState() => _BlocListenerState<B, S>();
}

class _BlocListenerState<B extends BlocBase<S>, S>
    extends State<BlocListener<B, S>>
    with BlocSubscriptionMixin<BlocListener<B, S>> {
  @override
  void initState() {
    super.initState();
    final B bloc = component.bloc ?? BlocProvider.of<B>(context);
    subscribeTo<B, S>(
      bloc,
      onState: (state) => component.listener(context, state),
      filter: component.listenWhen,
    );
  }

  @override
  Component build(BuildContext context) {
    return component.child;
  }
}
