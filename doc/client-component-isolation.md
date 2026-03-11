# `@client` Component Isolation

In Jaspr, you can annotate components with `@client` to create
interactive island components. Each `@client` annotation starts an
independent component tree. `BlocProvider` instances are scoped to
their own tree and are **not** accessible across `@client` boundaries.

## The Isolation Problem

When two separate `@client` components need to share the same bloc,
a `BlocProvider` placed in one tree cannot be read from the other:

```dart
// ❌ Does NOT work across @client boundaries.
// CounterDisplay and CounterControls live in separate trees.

@client
class CounterDisplay extends StatelessComponent {
  @override
  Component build(BuildContext context) {
    return BlocProvider<CounterCubit>(
      create: (_) => CounterCubit(),
      child: _CounterText(),
    );
  }
}

@client
class CounterControls extends StatelessComponent {
  @override
  Component build(BuildContext context) {
    // ❌ Throws — no BlocProvider<CounterCubit> in this tree.
    return BlocBuilder<CounterCubit, int>(
      builder: (context, count) => div([Component.text('$count')]),
    );
  }
}
```

## The Global Container Pattern

Create the bloc outside all `@client` trees so it is owned at the
application level. Then inject it into each island using
`BlocProvider.value`, which provides an existing instance without
taking ownership of its lifecycle.

### Step 1 — Declare a global bloc instance

```dart
// app_state.dart
import 'package:jaspr_bloc/jaspr_bloc.dart';
import 'counter_cubit.dart';

/// Shared bloc for the counter islands.
///
/// Declared at the top level so it survives across @client trees.
/// Close manually if the application has a defined shutdown point.
final counterCubit = CounterCubit();
```

### Step 2 — Inject into each island with `BlocProvider.value`

```dart
// counter_display.dart
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_bloc/jaspr_bloc.dart';
import 'app_state.dart';
import 'counter_cubit.dart';

@client
class CounterDisplay extends StatelessComponent {
  const CounterDisplay({super.key});

  @override
  Component build(BuildContext context) {
    // BlocProvider.value does not close the bloc on dispose.
    // The global instance remains alive for other islands.
    return BlocProvider<CounterCubit>.value(
      value: counterCubit,
      child: const _CounterText(),
    );
  }
}

class _CounterText extends StatelessComponent {
  const _CounterText();

  @override
  Component build(BuildContext context) {
    return BlocBuilder<CounterCubit, int>(
      builder: (context, count) {
        return span([Component.text('Count: $count')]);
      },
    );
  }
}
```

```dart
// counter_controls.dart
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_bloc/jaspr_bloc.dart';
import 'app_state.dart';
import 'counter_cubit.dart';

@client
class CounterControls extends StatelessComponent {
  const CounterControls({super.key});

  @override
  Component build(BuildContext context) {
    return BlocProvider<CounterCubit>.value(
      value: counterCubit,
      child: const _CounterButtons(),
    );
  }
}

class _CounterButtons extends StatelessComponent {
  const _CounterButtons();

  @override
  Component build(BuildContext context) {
    return div([
      button(
        events: {
          'click': (_) => context.read<CounterCubit>().increment(),
        },
        [Component.text('+')],
      ),
      button(
        events: {
          'click': (_) => context.read<CounterCubit>().decrement(),
        },
        [Component.text('-')],
      ),
    ]);
  }
}
```

### Step 3 — Use both islands in your page

```dart
// home_page.dart
import 'package:jaspr/jaspr.dart';

class HomePage extends StatelessComponent {
  const HomePage({super.key});

  @override
  Component build(BuildContext context) {
    return div([
      // Each island mounts independently and shares counterCubit.
      const CounterDisplay(),
      const CounterControls(),
    ]);
  }
}
```

## Key Points

- `BlocProvider` (default constructor) **creates and owns** the bloc.
  It is scoped to its component tree and cannot cross `@client`
  boundaries.
- `BlocProvider.value` **provides an existing instance** without
  taking ownership. Use this to share a globally-held bloc across
  islands.
- The global variable is responsible for the bloc lifecycle. For most
  apps the process lifetime is sufficient; call `bloc.close()` in an
  application teardown hook if needed.
- This pattern mirrors the recommended approach in the Jaspr
  documentation for sharing state across island component trees.
