import 'package:jaspr/jaspr.dart';

/// Exception thrown when a requested provider cannot be found in the
/// component ancestry.
///
/// This mirrors `ProviderNotFoundException` from the Flutter `provider`
/// package so code which catches that exception can use the same pattern in
/// Jaspr applications.
class ProviderNotFoundException implements Exception {
  /// Creates a [ProviderNotFoundException].
  ProviderNotFoundException(this.valueType, this.widgetType);

  /// The type of value which was requested.
  final Type valueType;

  /// The type of component whose context initiated the lookup.
  final Type widgetType;

  @override
  String toString() {
    return 'Error: Could not find the correct Provider<$valueType> above this '
        '$widgetType Component.\n\n'
        'This happens because the context used does not include the provider '
        'of your choice.';
  }
}

/// Exception thrown when a non-nullable lookup finds a provider whose value
/// is null.
///
/// This is kept out of the root export, matching `flutter_bloc`, which only
/// re-exports `ProviderNotFoundException` from Provider.
class ProviderNullException implements Exception {
  /// Creates a [ProviderNullException].
  ProviderNullException(this.valueType, this.widgetType);

  /// The non-nullable type which was requested.
  final Type valueType;

  /// The component which requested the value.
  final Type widgetType;

  @override
  String toString() {
    return 'Error: The component $widgetType tried to read Provider<$valueType> '
        'but the matching provider returned null.';
  }
}

/// Internal Jaspr counterpart of Provider's `SingleChildWidget` contract.
///
/// It is intentionally not exported from `package:jaspr_bloc/jaspr_bloc.dart`.
abstract interface class SingleChildComponent {
  /// Returns an equivalent component whose child is [child].
  Component copyWithChild(Component child);
}
