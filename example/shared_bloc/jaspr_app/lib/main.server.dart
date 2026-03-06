import 'package:jaspr/server.dart';

import 'counter_page.dart';

/// Server entry point for the Jaspr shared-bloc example app.
void main() {
  Jaspr.initializeApp();

  runApp(const Document(title: 'Shared Bloc Counter — Jaspr', body: _App()));
}

/// Root application component.
///
/// Renders [CounterPage] which is marked [@client] and will be
/// hydrated in the browser after the server-rendered HTML loads.
class _App extends StatelessComponent {
  const _App();

  @override
  Component build(BuildContext context) {
    return const CounterPage();
  }
}
