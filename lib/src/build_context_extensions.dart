import 'package:jaspr/jaspr.dart';

import 'provider_inherited.dart';

/// Exposes a `read` method on [BuildContext].
///
/// This mirrors `ReadContext` from Flutter's `provider` package and works for
/// blocs, repositories, and any other value supplied by a jaspr_bloc provider.
extension ReadContext on BuildContext {
  /// Obtains the nearest value of type [T] without listening to it.
  T read<T>() => ProviderInherited.read<T>(this);
}

/// Exposes a `watch` method on [BuildContext].
extension WatchContext on BuildContext {
  /// Obtains the nearest value of type [T] and rebuilds whenever the provider
  /// notifies its dependents.
  T watch<T>() => ProviderInherited.watch<T>(this);
}

/// Exposes a selected-value dependency on [BuildContext].
extension SelectContext on BuildContext {
  /// Watches only the result returned by [selector].
  ///
  /// The dependent rebuilds when the selected result changes according to
  /// Provider-compatible deep collection equality.
  R select<T, R>(R Function(T value) selector) {
    return ProviderInherited.select<T, R>(this, selector);
  }
}
