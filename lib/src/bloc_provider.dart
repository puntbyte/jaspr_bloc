import 'package:bloc/bloc.dart';
import 'package:jaspr/jaspr.dart';

import 'bloc_inherited.dart';

/// Signature for a function that creates a [BlocBase] instance from a
/// [BuildContext].
typedef BlocCreator<T> = T Function(BuildContext context);

/// A Jaspr component that provides a [BlocBase] instance to its descendants
/// via dependency injection.
///
/// [BlocProvider] uses [InheritedComponent] to make a bloc or cubit accessible
/// to all descendant components in the component tree.
///
/// Use the default constructor when you want [BlocProvider] to create and
/// manage the lifecycle of the bloc:
///
/// ```dart
/// BlocProvider<CounterCubit>(
///   create: (context) => CounterCubit(),
///   child: CounterPage(),
/// )
/// ```
///
/// Use the [BlocProvider.value] constructor when you want to provide an
/// existing bloc instance without managing its lifecycle:
///
/// ```dart
/// BlocProvider.value(
///   value: existingCubit,
///   child: CounterPage(),
/// )
/// ```
///
/// Descendants can access the bloc using [BlocProvider.of]:
///
/// ```dart
/// final cubit = BlocProvider.of<CounterCubit>(context);
/// ```
///
/// Or via the [BuildContext] extension:
///
/// ```dart
/// final cubit = context.read<CounterCubit>();
/// ```
class BlocProvider<T extends BlocBase<Object?>> extends StatefulComponent {
  final BlocCreator<T>? _create;
  final T? _value;
  final bool _manageLifecycle;

  /// The child component that will have access to the provided bloc.
  final Component child;

  /// Creates a [BlocProvider] that creates and manages the lifecycle of [T].
  ///
  /// The [create] function is called once when the component is initialized
  /// to create the bloc instance. The bloc is automatically closed when
  /// this component is disposed.
  const BlocProvider({
    required BlocCreator<T> create,
    required this.child,
    super.key,
  }) : _create = create,
       _value = null,
       _manageLifecycle = true;

  /// Creates a [BlocProvider] that provides an existing [value] bloc.
  ///
  /// The provided bloc is NOT closed when this component is disposed.
  /// Use this constructor when the bloc's lifecycle is managed externally.
  const BlocProvider.value({required T value, required this.child, super.key})
    : _value = value,
      _create = null,
      _manageLifecycle = false;

  /// Retrieves the nearest [BlocProvider<T>] ancestor's bloc from [context].
  ///
  /// Does not subscribe to changes. The calling component will not rebuild
  /// when the bloc instance provided by [BlocProvider] changes.
  ///
  /// Typically used in event handlers or callbacks where reactive rebuilds
  /// are not needed:
  ///
  /// ```dart
  /// onTap: () => BlocProvider.of<CounterCubit>(context).increment(),
  /// ```
  ///
  /// Throws an [AssertionError] if no [BlocProvider<T>] is found in the
  /// ancestor tree.
  static T of<T extends BlocBase<Object?>>(BuildContext context) {
    return BlocInherited.readOf<T>(context);
  }

  @override
  State<BlocProvider<T>> createState() => _BlocProviderState<T>();
}

class _BlocProviderState<T extends BlocBase<Object?>>
    extends State<BlocProvider<T>> {
  late T _bloc;

  @override
  void initState() {
    super.initState();
    if (component._value != null) {
      _bloc = component._value!;
    } else {
      _bloc = component._create!(context);
    }
  }

  @override
  void dispose() {
    if (component._manageLifecycle) {
      _bloc.close();
    }
    super.dispose();
  }

  @override
  Component build(BuildContext context) {
    return BlocInherited<T>(bloc: _bloc, child: component.child);
  }
}
