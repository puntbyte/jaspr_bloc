# Shared Bloc Example

A mono-repo example demonstrating how a single pure-Dart bloc package
(`common_blocs`) can be shared between a **Flutter** app and a **Jaspr**
web app without any modification to the bloc code.

## Structure

```
shared_bloc/
  common_blocs/      — Shared pure-Dart package (CounterCubit)
  flutter_app/       — Flutter app using flutter_bloc
  jaspr_app/         — Jaspr web app using jaspr_bloc
```

## Architecture

The key insight is that `bloc` cubits and blocs contain zero
UI-framework code. They depend only on the `bloc` package, which
is a plain Dart library. This means the same cubit file can be
imported by:

- A **Flutter** app via `flutter_bloc`
- A **Jaspr** app via `jaspr_bloc`

```
common_blocs/
  lib/
    src/counter/counter_cubit.dart   ← imported unchanged by both apps
```

```
flutter_app  ──┐
               ├── common_blocs (CounterCubit)
jaspr_app    ──┘
```

`flutter_app` wires `CounterCubit` through `flutter_bloc`'s
`BlocProvider` and `BlocBuilder`. `jaspr_app` wires the same cubit
through `jaspr_bloc`'s `BlocProvider` and `BlocBuilder`. The cubit
itself never changes.

## Running the Jaspr App

```bash
cd jaspr_app
dart pub get
dart run build_runner build
jaspr serve
```

Open `http://localhost:8080` in a browser.

## Running the Flutter App

```bash
cd flutter_app
flutter pub get
flutter run
```

## Key Points

- `common_blocs` depends only on `bloc` — no Flutter, no Jaspr.
- Both apps declare `common_blocs` as a path dependency.
- `CounterCubit` is imported with the same import statement in both apps:
  `import 'package:common_blocs/common_blocs.dart';`
- The cubit is tested once in `common_blocs` and reused everywhere.
