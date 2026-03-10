import 'package:jaspr/jaspr.dart';

/// Whether stream subscriptions should be activated in the current environment.
///
/// Defaults to `kIsWeb` — `true` in the browser, `false` on the server during
/// SSR. When `false`, [BlocProvider], [BlocBuilder], [BlocListener],
/// [BlocConsumer], and [BlocSelector] skip stream subscription creation so
/// that server-side rendering (SSR) remains purely synchronous.
///
/// Override this value in tests using [setIsClientForTesting] so that reactive
/// behavior can be verified in the Dart VM test environment.
bool _isClient = kIsWeb;

/// Returns `true` when the current environment should activate stream
/// subscriptions (i.e. client / browser side).
bool get isClientEnvironment => _isClient;

/// Overrides [isClientEnvironment] for testing purposes.
///
/// Call this in a `setUp` callback to simulate a client environment in tests
/// that verify reactive bloc behavior. Always pair with
/// [resetIsClientForTesting] in `tearDown`.
///
/// ```dart
/// setUp(() => setIsClientForTesting(true));
/// tearDown(() => resetIsClientForTesting());
/// ```
// ignore: avoid_positional_boolean_parameters
void setIsClientForTesting(bool value) => _isClient = value;

/// Resets [isClientEnvironment] to the default value (`kIsWeb`).
///
/// Call this in a `tearDown` callback after using [setIsClientForTesting].
void resetIsClientForTesting() => _isClient = kIsWeb;
