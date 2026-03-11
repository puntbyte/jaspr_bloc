# jaspr_bloc

BLoC state management for [Jaspr](https://jaspr.site/) web applications. Like `flutter_bloc` or
`angular_bloc` — but for Jaspr. Share identical `Bloc` / `Cubit` business logic across Flutter and
Jaspr with zero modification.

## Installation

```yaml
dependencies:
  jaspr_bloc: ^0.1.0
```

## Quick Start

```dart
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_bloc/jaspr_bloc.dart';

// 1. Define a Cubit (identical to Flutter).
class CounterCubit extends Cubit<int> {
  CounterCubit() : super(0);
  void increment() => emit(state + 1);
  void decrement() => emit(state - 1);
}

// 2. Provide it.
BlocProvider<CounterCubit>(
  create: (context) => CounterCubit(),
  child: const CounterPage(),
)

// 3. Build reactive UI.
BlocBuilder<CounterCubit, int>(
  builder: (context, count) {
    return span([Component.text('Count: $count')]);
  },
)

// 4. Dispatch events.
context.read<CounterCubit>().increment();
```

## Components

| Component | Purpose |
|---|---|
| `BlocProvider` | Provides a bloc to a component subtree |
| `MultiBlocProvider` | Provides multiple blocs without deep nesting |
| `BlocBuilder` | Rebuilds UI on state changes |
| `BlocListener` | Runs side effects on state changes |
| `MultiBlocListener` | Multiple listeners without deep nesting |
| `BlocConsumer` | Combines `BlocBuilder` and `BlocListener` |
| `BlocSelector` | Rebuilds only when a selected value changes |
| `RepositoryProvider` | Provides a repository to a subtree |
| `MultiRepositoryProvider` | Provides multiple repositories |
| `context.read<T>()` | Reads a bloc without subscribing |
| `context.watch<T>()` | Reads a bloc and subscribes to changes |
| `context.select(...)` | Selects a derived value from a bloc |

## Component Examples

### BlocProvider

Provides a bloc instance to all descendant components. The bloc is created once and closed
automatically when the provider is disposed.

```dart
BlocProvider<CounterCubit>(
  create: (context) => CounterCubit(),
  child: const CounterPage(),
)
```

Use `BlocProvider.value` to provide an already-existing instance without taking ownership of its
lifecycle:

```dart
BlocProvider<CounterCubit>.value(
  value: existingCubit,
  child: const CounterPage(),
)
```

Read the provided bloc anywhere in the subtree:

```dart
final cubit = BlocProvider.of<CounterCubit>(context);
// or via extension:
final cubit = context.read<CounterCubit>();
```

### MultiBlocProvider

Provides multiple blocs without deeply nested constructors:

```dart
MultiBlocProvider(
  providers: [
    BlocProvider<CounterCubit>(create: (_) => CounterCubit()),
    BlocProvider<AuthBloc>(create: (_) => AuthBloc()),
  ],
  child: const HomePage(),
)
```

### BlocBuilder

Rebuilds its UI whenever the bloc emits a new state. Use `buildWhen` to filter rebuilds:

```dart
BlocBuilder<CounterCubit, int>(
  buildWhen: (previous, current) => current != previous,
  builder: (context, count) {
    return span([Component.text('Count: $count')]);
  },
)
```

### BlocListener

Runs a side effect callback on state changes without rebuilding its child. Ideal for navigation,
toasts, or analytics:

```dart
BlocListener<AuthBloc, AuthState>(
  listenWhen: (previous, current) => current is AuthFailure,
  listener: (context, state) {
    // Show error toast, redirect to login, etc.
  },
  child: const LoginForm(),
)
```

### MultiBlocListener

Attaches multiple listeners without deep nesting:

```dart
MultiBlocListener(
  listeners: [
    BlocListener<AuthBloc, AuthState>(
      listener: (context, state) { /* handle auth */ },
      child: const SizedBox(),
    ),
    BlocListener<NotificationBloc, NotificationState>(
      listener: (context, state) { /* handle notification */ },
      child: const SizedBox(),
    ),
  ],
  child: const HomePage(),
)
```

### BlocConsumer

Combines builder and listener in a single component with one stream subscription:

```dart
BlocConsumer<CounterCubit, int>(
  listenWhen: (previous, current) => current == 10,
  listener: (context, state) {
    // Show a toast when state reaches 10.
  },
  buildWhen: (previous, current) => current % 2 == 0,
  builder: (context, count) {
    return span([Component.text('Even count: $count')]);
  },
)
```

### BlocSelector

Rebuilds only when a derived value extracted from the state changes. Prevents unnecessary rebuilds
when unrelated parts of the state update:

```dart
BlocSelector<UserBloc, UserState, String>(
  selector: (state) => state.displayName,
  builder: (context, displayName) {
    return span([Component.text('Hello, $displayName')]);
  },
)
```

### RepositoryProvider

Provides a repository or service to descendants. Unlike `BlocProvider`, it does not manage any
lifecycle — the repository is not closed on dispose:

```dart
RepositoryProvider<UserRepository>(
  create: (context) => UserRepository(),
  child: const UserPage(),
)

// Access anywhere in the subtree:
final repo = RepositoryProvider.of<UserRepository>(context);
```

Use `MultiRepositoryProvider` to avoid nesting:

```dart
MultiRepositoryProvider(
  providers: [
    RepositoryProvider<UserRepository>(create: (_) => UserRepository()),
    RepositoryProvider<ApiClient>(create: (_) => ApiClient()),
  ],
  child: const App(),
)
```

### Context Extensions

`jaspr_bloc` adds three ergonomic extensions on `BuildContext`:

```dart
// Read a bloc without subscribing (use for dispatching events).
context.read<CounterCubit>().increment();

// Watch a bloc — subscribes and rebuilds on every state change.
final cubit = context.watch<CounterCubit>();

// Select a derived value from a bloc's state.
final name = context.select<UserBloc, UserState, String>(
  (state) => state.displayName,
);
```

## SSR Support

All components are SSR-safe. During server-side rendering no stream subscriptions are created.
After client hydration, subscriptions activate automatically and components become reactive.

There is no special configuration needed. Drop `BlocProvider` and `BlocBuilder` into any Jaspr
component tree and they work correctly on both server and client.

### `@client` Component Guidance

Jaspr's `@client` annotation creates isolated component trees (islands). A `BlocProvider` placed
inside one `@client` tree is **not** visible to another `@client` tree. To share a bloc across
multiple islands, hold the bloc at the application level and inject it with `BlocProvider.value`:

```dart
// app_state.dart — global bloc instance shared across islands.
final counterCubit = CounterCubit();

// island_a.dart
@client
class CounterDisplay extends StatelessComponent {
  @override
  Component build(BuildContext context) {
    return BlocProvider<CounterCubit>.value(
      value: counterCubit,
      child: BlocBuilder<CounterCubit, int>(
        builder: (context, count) => span([Component.text('$count')]),
      ),
    );
  }
}

// island_b.dart
@client
class CounterControls extends StatelessComponent {
  @override
  Component build(BuildContext context) {
    return BlocProvider<CounterCubit>.value(
      value: counterCubit,
      child: button(
        events: {'click': (_) => context.read<CounterCubit>().increment()},
        [Component.text('+')],
      ),
    );
  }
}
```

See [Client Component Isolation](./docs/client-component-isolation.md) for the full pattern and
explanation.

## flutter_bloc vs jaspr_bloc

| Feature | `flutter_bloc` | `jaspr_bloc` |
|---|---|---|
| Target platform | Flutter (mobile, desktop, web) | Jaspr (web only) |
| Bloc / Cubit classes | `package:bloc` | Same `package:bloc` |
| Provider component | `BlocProvider` | `BlocProvider` (identical API) |
| Builder component | `BlocBuilder` | `BlocBuilder` (identical API) |
| Listener component | `BlocListener` | `BlocListener` (identical API) |
| Consumer component | `BlocConsumer` | `BlocConsumer` (identical API) |
| Selector component | `BlocSelector` | `BlocSelector` (identical API) |
| Repository provider | `RepositoryProvider` | `RepositoryProvider` (identical API) |
| Multi-providers | `MultiBlocProvider` etc. | `MultiBlocProvider` etc. (identical API) |
| Context extensions | `context.read`, `watch`, `select` | `context.read`, `watch`, `select` (identical API) |
| SSR support | Not applicable | Built-in, no configuration |
| `@client` island sharing | Not applicable | `BlocProvider.value` global pattern |
| Base class | `StatelessWidget` / `StatefulWidget` | `StatelessComponent` / `StatefulComponent` |
| Shared business logic | — | Bloc/Cubit files import without modification |

The Bloc and Cubit classes live in `package:bloc` and are shared by both libraries. You can keep
your business logic in a separate `common_blocs` package and import it unchanged in both Flutter
and Jaspr apps. Only the UI layer differs.

## Testing

When writing Dart VM tests for components that use `BlocBuilder`, `BlocListener`, or other
reactive jaspr_bloc components, import `package:jaspr_bloc/testing.dart` and call
`setIsClientForTesting(true)` in `setUp` to enable stream subscriptions outside the browser:

```dart
import 'package:jaspr_bloc/testing.dart';

void main() {
  setUp(() => setIsClientForTesting(true));
  tearDown(() => resetIsClientForTesting());

  test('counter increments', () {
    // BlocBuilder and friends now subscribe to streams in the Dart VM.
  });
}
```

## Documentation

- [Client Component Isolation](./docs/client-component-isolation.md) —
  Sharing blocs across `@client` island trees with `BlocProvider.value`.
- [Integration Testing](./docs/integration-testing.md) —
  Writing integration tests with `jaspr_test`.
