/// Testing utilities for jaspr_bloc.
///
/// Import this library in your test files to enable client-mode simulation,
/// which is required for testing reactive bloc behavior outside of a browser
/// environment.
///
/// ```dart
/// import 'package:jaspr_bloc/testing.dart';
///
/// void main() {
///   setUp(() => setIsClientForTesting(true));
///   tearDown(() => resetIsClientForTesting());
///
///   test('my bloc test', () {
///     // BlocBuilder, BlocListener, etc. now subscribe to streams.
///   });
/// }
/// ```
library;

export 'src/jaspr_bloc_config.dart'
    show resetIsClientForTesting, setIsClientForTesting;
