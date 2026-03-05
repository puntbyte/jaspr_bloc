import 'package:jaspr/server.dart';

import 'counter_page.dart';

void main() {
  Jaspr.initializeApp();

  runApp(const Document(title: 'Jaspr Bloc Counter', body: App()));
}

/// Root application component.
///
/// Renders [CounterPage] which is marked [@client] and will be
/// hydrated in the browser after the server-rendered HTML loads.
class App extends StatelessComponent {
  const App({super.key});

  @override
  Component build(BuildContext context) {
    return const CounterPage();
  }
}
