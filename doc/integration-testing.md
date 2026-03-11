# Integration Testing

Integration tests verify that multiple jaspr_bloc components work together correctly in a
realistic app scenario. They live under `test/integration/` and use `jaspr_test`.

## Running integration tests

```bash
dart test test/integration/
```

## Counter app integration test

`test/integration/counter_integration_test.dart` mirrors the structure of the counter example
app (`example/counter/`). It sets up a `BlocProvider<CounterCubit>` and a view that renders
the count with `BlocBuilder` and exposes increment/decrement buttons.

Tests cover:

- Initial render shows the correct count and buttons.
- Calling `increment()` updates the displayed count.
- Multiple increments accumulate correctly.
- Calling `decrement()` reduces the count, including below zero.
- Mixed increment/decrement sequences render the correct value.

The test component tree is equivalent to the example app but without the `@client` annotation,
which is not needed in a test environment where `setIsClientForTesting(true)` is used instead.

## Multi-bloc interaction test

`test/integration/multi_bloc_integration_test.dart` tests two realistic scenarios where
multiple blocs interact through the presentation layer.

### Counter with log

A `CounterCubit` and a `LogCubit` are provided via `MultiBlocProvider`. A `BlocListener` on
`CounterCubit` calls `LogCubit.addEntry` when the counter changes. Neither cubit holds a
reference to the other — all coordination happens in the component tree.

Tests cover:

- Initial state: count 0, empty log.
- Each increment appends a log entry describing the new count.
- Three increments produce three distinct log entries.
- Manually appending a log entry does not affect the counter view.

### Dual counter with shared score

Two independent counters (`_CounterACubit`, `_CounterBCubit`) each drive a shared `ScoreCubit`
through separate `BlocListener` widgets. Counter A adds 1 point per increment; counter B adds
10 points.

Tests cover:

- Initial state: both counters and score at zero.
- Counter A increment adds 1 to the score.
- Counter B increment adds 10 to the score.
- Interleaved increments from both counters accumulate correctly.
- Only the incremented counter's view updates; the other stays unchanged.

## Test helpers

`test/helpers/client_mode.dart` re-exports `setIsClientForTesting` and
`resetIsClientForTesting` from `jaspr_bloc_config`. Every integration test calls
`setIsClientForTesting(true)` in `setUp` and `resetIsClientForTesting()` in `tearDown` so
that components that check `isClient` behave as they would in a live browser.
