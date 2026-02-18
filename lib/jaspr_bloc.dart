/// A state management package for Jaspr that implements the BLoC pattern.
///
/// This library provides BLoC (Business Logic Component) pattern support for
/// Jaspr web applications, enabling Jaspr apps to handle state the same
/// way as Flutter apps.
library;

// Export bloc package for convenience
export 'package:bloc/bloc.dart';

// Export context extensions for ergonomic bloc access
export 'src/build_context_extensions.dart';

// Export dependency injection components
export 'src/bloc_provider.dart';
export 'src/multi_bloc_provider.dart';
export 'src/multi_repository_provider.dart';
export 'src/repository_provider.dart';

// Export mixin for subscription lifecycle management
export 'src/bloc_subscription_mixin.dart';
