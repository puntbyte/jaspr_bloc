# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

Version numbers are aligned with the `bloc` ecosystem convention:
major versions track breaking changes, minor versions track new components,
and patch versions track bug fixes and documentation updates.

## [1.0.1] - 2026-03-11

### Fixed

- Correct repository URL in `pubspec.yaml` to point to the right GitHub repository.
- Add top-level `example/example.dart` so pub.dev recognizes the example correctly.
- Hide undocumented abstract protocol types (`BlocEventSink`, `Closable`, `Emittable`,
  `EmittableStateStreamableSource`, `Emitter`) from the `package:bloc` re-export so all
  public API elements in jaspr_bloc have dartdoc coverage.

## [1.0.0] - 2026-03-11

### Added

**Dependency Injection**

- `BlocProvider` — provides a `Bloc` or `Cubit` instance to a descendant component subtree
  via `InheritedComponent`; creates and closes the bloc automatically
- `BlocProvider.value` — provides an existing bloc instance without taking ownership of its
  lifecycle; required for sharing blocs across `@client` island boundaries
- `BlocProvider.of<T>` — static accessor to retrieve a bloc from the nearest ancestor provider
- `MultiBlocProvider` — composes multiple `BlocProvider` instances without deep nesting
- `RepositoryProvider` — provides any non-bloc dependency (repositories, services, data sources)
  to a subtree; does not manage lifecycle
- `RepositoryProvider.value` — provides an existing repository instance without ownership
- `RepositoryProvider.of<T>` — static accessor to retrieve a repository from the nearest ancestor
- `MultiRepositoryProvider` — composes multiple `RepositoryProvider` instances without nesting

**Reactive UI**

- `BlocBuilder` — rebuilds its subtree on every bloc state emission; supports `buildWhen`
  predicate to filter rebuilds
- `BlocListener` — runs a side-effect callback on state changes without rebuilding its child;
  supports `listenWhen` predicate to filter invocations
- `MultiBlocListener` — composes multiple `BlocListener` instances without deep nesting
- `BlocConsumer` — combines `BlocBuilder` and `BlocListener` in a single component backed by
  one stream subscription; supports independent `buildWhen` and `listenWhen` predicates
- `BlocSelector` — rebuilds only when a value derived from the state changes via `==` equality;
  accepts a `selector` function and a `builder` callback

**Context Extensions**

- `context.read<T>()` — retrieves the nearest `BlocProvider<T>` bloc without subscribing;
  intended for dispatching events from callbacks
- `context.watch<T>()` — retrieves the nearest `BlocProvider<T>` bloc and subscribes to rebuild
  notifications; intended for use inside `build` methods
- `context.select<T, S, R>(selector)` — retrieves the nearest `BlocProvider<T>` bloc, subscribes,
  and returns a derived value from the current state

**SSR Compatibility**

- All components are server-side rendering safe; no stream subscriptions are created during
  SSR and subscriptions activate automatically after client hydration
- `isClientEnvironment` — internal flag that guards stream subscriptions; exposed as
  `resetIsClientForTesting` for unit test isolation

**Examples**

- `example/counter/` — minimal counter app demonstrating `BlocProvider`, `BlocBuilder`,
  `CounterCubit`, and `context.read` within a `@client` component
- `example/shared_bloc/` — mono-repo demonstrating a pure-Dart `common_blocs` package shared
  unchanged between a Flutter app and a Jaspr app

**Documentation**

- Full dartdoc comments on all public APIs with usage examples
- `doc/client-component-isolation.md` — guide for sharing blocs across `@client` island
  boundaries using the `BlocProvider.value` global container pattern
- Comprehensive README with quick start, per-component code examples, SSR guidance, and a
  `flutter_bloc` vs `jaspr_bloc` comparison table
