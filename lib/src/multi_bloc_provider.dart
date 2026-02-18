import 'package:bloc/bloc.dart';
import 'package:jaspr/jaspr.dart';

import 'bloc_provider.dart';

/// A Jaspr component that merges multiple [BlocProvider] components into one
/// widget tree.
///
/// [MultiBlocProvider] improves the readability and eliminates the need to
/// deeply nest multiple [BlocProvider] components.
///
/// Instead of:
/// ```dart
/// BlocProvider<BlocA>(
///   create: (_) => BlocA(),
///   child: BlocProvider<BlocB>(
///     create: (_) => BlocB(),
///     child: MyPage(),
///   ),
/// )
/// ```
///
/// Use:
/// ```dart
/// MultiBlocProvider(
///   providers: [
///     BlocProvider<BlocA>(create: (_) => BlocA()),
///     BlocProvider<BlocB>(create: (_) => BlocB()),
///   ],
///   child: MyPage(),
/// )
/// ```
///
/// [MultiBlocProvider] nests the providers from left to right, so the first
/// provider in the list is the outermost ancestor in the component tree.
class MultiBlocProvider extends StatelessComponent {
  /// The list of [BlocProvider] components to nest.
  ///
  /// Each provider in the list should omit the [child] argument —
  /// [MultiBlocProvider] assigns children automatically during composition.
  final List<BlocProvider<BlocBase<Object?>>> providers;

  /// The child component that has access to all provided blocs.
  final Component child;

  /// Creates a [MultiBlocProvider].
  ///
  /// [providers] is required and must not be empty.
  /// [child] is the component placed at the innermost level of the tree.
  const MultiBlocProvider({
    required this.providers,
    required this.child,
    super.key,
  });

  @override
  Component build(BuildContext context) {
    return providers.reversed.fold<Component>(
      child,
      (innerChild, provider) => provider.copyWithChild(innerChild),
    );
  }
}
