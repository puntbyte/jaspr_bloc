import 'package:bloc/bloc.dart';
import 'package:jaspr/jaspr.dart';

import 'bloc_builder.dart';
import 'bloc_provider.dart';
import 'bloc_subscription_mixin.dart';

/// Signature for a function that derives a value [T] from a bloc state [S].
typedef BlocWidgetSelector<S, T> = T Function(S state);

/// A Jaspr component that rebuilds its UI only when a derived value selected
/// from the bloc state changes.
///
/// [BlocSelector] subscribes to the bloc's [Stream] and applies the [selector]
/// function to each new state. A rebuild is triggered only when the selected
/// value [T] changes according to `==` equality. This prevents unnecessary
/// rebuilds when unrelated parts of the state are updated.
///
/// The [builder] callback receives the `BuildContext` and the selected value
/// [T], not the full state [S].
///
/// By default the nearest ancestor [BlocProvider] supplies the bloc. You may
/// override this by passing an explicit [bloc] parameter.
///
/// ```dart
/// BlocSelector<UserBloc, UserState, String>(
///   selector: (state) => state.displayName,
///   builder: (context, displayName) {
///     return span([Component.text('Hello, $displayName')]);
///   },
/// )
/// ```
class BlocSelector<B extends BlocBase<S>, S, T> extends StatefulComponent {
  /// Creates a [BlocSelector].
  ///
  /// Both [selector] and [builder] are required.
  ///
  /// If [bloc] is omitted the nearest ancestor [BlocProvider<B>] is used.
  const BlocSelector({
    required this.selector,
    required this.builder,
    this.bloc,
    super.key,
  });

  /// An optional explicit bloc instance.
  ///
  /// When non-null, this bloc is used instead of the nearest ancestor
  /// [BlocProvider<B>].
  final B? bloc;

  /// A function that derives the value [T] from the bloc state [S].
  ///
  /// Called on each state emission to determine whether a rebuild is needed.
  /// A rebuild occurs only when the returned value differs from the previous
  /// selected value (using `==` equality).
  final BlocWidgetSelector<S, T> selector;

  /// Called every time the component needs to rebuild.
  ///
  /// Receives the `BuildContext` and the current selected value [T].
  final BlocWidgetBuilder<T> builder;

  @override
  State<BlocSelector<B, S, T>> createState() => _BlocSelectorState<B, S, T>();
}

class _BlocSelectorState<B extends BlocBase<S>, S, T>
    extends State<BlocSelector<B, S, T>>
    with BlocSubscriptionMixin<BlocSelector<B, S, T>> {
  late T _selected;

  @override
  void initState() {
    super.initState();
    final B bloc = component.bloc ?? BlocProvider.of<B>(context);
    _selected = component.selector(bloc.state);
    subscribeTo<B, S>(
      bloc,
      onState: (state) {
        final T next = component.selector(state);
        if (next != _selected) {
          setState(() {
            _selected = next;
          });
        }
      },
    );
  }

  @override
  Component build(BuildContext context) {
    return component.builder(context, _selected);
  }
}
