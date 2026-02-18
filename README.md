# jaspr_bloc

BLoC state management for [Jaspr](https://jaspr.site/) web applications.
Like `flutter_bloc` or `angular_bloc` — but for Jaspr. Share identical
`Bloc` / `Cubit` business logic across Flutter and Jaspr with zero
modification.

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

## SSR Support

All components are SSR-safe. During server-side rendering no stream
subscriptions are created. After client hydration, subscriptions
activate automatically and components become reactive.

## Documentation

- [Client Component Isolation](./docs/client-component-isolation.md) —
  Sharing blocs across `@client` island trees with `BlocProvider.value`.
