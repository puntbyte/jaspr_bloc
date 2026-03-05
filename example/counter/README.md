# Counter Example

A minimal Jaspr app demonstrating `jaspr_bloc` usage with
`BlocProvider`, `BlocBuilder`, and a `CounterCubit`.

## Structure

```
lib/
  counter_cubit.dart   — Pure Dart cubit (shared with Flutter)
  counter_page.dart    — @client component with BlocProvider + BlocBuilder
  main.server.dart     — Server entry point
```

## Running

```bash
dart pub get
dart run build_runner build
jaspr serve
```

Open `http://localhost:8080` in a browser and use the `+` / `-` buttons
to increment and decrement the counter.

## Key Concepts

- `CounterCubit` is plain Dart — identical to a Flutter cubit.
- `CounterPage` is annotated `@client` so it is hydrated in the
  browser and becomes interactive.
- `BlocProvider` creates the cubit inside the `@client` tree so
  stream subscriptions activate after hydration.
- `BlocBuilder` rebuilds the count label on every state change.
- `context.read<CounterCubit>()` dispatches calls from button
  handlers without subscribing to state updates.
