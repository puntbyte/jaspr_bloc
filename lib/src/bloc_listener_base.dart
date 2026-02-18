import 'package:jaspr/jaspr.dart';

/// Abstract base class for [BlocListener] variants used by [MultiBlocListener].
///
/// Provides the [copyWithChild] contract that [MultiBlocListener] uses to
/// compose a nested listener tree without requiring knowledge of the specific
/// [BlocListener] type parameters.
abstract class BlocListenerBase extends StatefulComponent {
  /// Creates a [BlocListenerBase].
  const BlocListenerBase({super.key});

  /// Creates a copy of this listener with [child] as the inner child component.
  ///
  /// Used internally by [MultiBlocListener] to compose a nested listener tree.
  /// Do not call this method directly.
  BlocListenerBase copyWithChild(Component child);
}
