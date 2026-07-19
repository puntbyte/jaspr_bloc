import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_bloc/jaspr_bloc.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../helpers/client_mode.dart';

class CounterCubit extends Cubit<int> {
  CounterCubit([super.initialState = 0]);

  void increment() => emit(state + 1);
}

class ProfileState {
  const ProfileState({required this.name, required this.age});

  final String name;
  final int age;
}

class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit() : super(const ProfileState(name: 'Alice', age: 30));

  void rename(String name) => emit(ProfileState(name: name, age: state.age));

  void birthday() => emit(ProfileState(name: state.name, age: state.age + 1));
}


class ListCubit extends Cubit<List<int>> {
  ListCubit() : super(const [1, 2, 3]);

  void emitEquivalent() => emit(List<int>.of(state));

  void append(int value) => emit([...state, value]);
}

class DisposableRepository {
  bool disposed = false;

  void dispose() => disposed = true;
}

class ProviderSwitcher extends StatefulComponent {
  const ProviderSwitcher({
    required this.first,
    required this.second,
    required this.onCreate,
    super.key,
  });

  final CounterCubit first;
  final CounterCubit second;
  final void Function(ProviderSwitcherState state) onCreate;

  @override
  State<ProviderSwitcher> createState() => ProviderSwitcherState();
}

class ProviderSwitcherState extends State<ProviderSwitcher> {
  bool useFirst = true;

  @override
  void initState() {
    super.initState();
    component.onCreate(this);
  }

  void switchBloc() => setState(() => useFirst = !useFirst);

  @override
  Component build(BuildContext context) {
    return BlocProvider<CounterCubit>.value(
      value: useFirst ? component.first : component.second,
      child: BlocBuilder<CounterCubit, int>(
        builder: (context, state) => div([Component.text('value:$state')]),
      ),
    );
  }
}

class ExplicitBlocSwitcher extends StatefulComponent {
  const ExplicitBlocSwitcher({
    required this.first,
    required this.second,
    required this.onCreate,
    super.key,
  });

  final CounterCubit first;
  final CounterCubit second;
  final void Function(ExplicitBlocSwitcherState state) onCreate;

  @override
  State<ExplicitBlocSwitcher> createState() => ExplicitBlocSwitcherState();
}

class ExplicitBlocSwitcherState extends State<ExplicitBlocSwitcher> {
  bool useFirst = true;

  @override
  void initState() {
    super.initState();
    component.onCreate(this);
  }

  void switchBloc() => setState(() => useFirst = !useFirst);

  @override
  Component build(BuildContext context) {
    return BlocBuilder<CounterCubit, int>(
      bloc: useFirst ? component.first : component.second,
      builder: (context, state) => div([Component.text('explicit:$state')]),
    );
  }
}

class SelectorSwitcher extends StatefulComponent {
  const SelectorSwitcher({
    required this.onCreate,
    required this.onBuild,
    super.key,
  });

  final void Function(SelectorSwitcherState state) onCreate;
  final void Function() onBuild;

  @override
  State<SelectorSwitcher> createState() => SelectorSwitcherState();
}

class SelectorSwitcherState extends State<SelectorSwitcher> {
  bool selectName = true;

  @override
  void initState() {
    super.initState();
    component.onCreate(this);
  }

  void selectAge() => setState(() => selectName = false);

  @override
  Component build(BuildContext context) {
    component.onBuild();
    final selected = selectName
        ? context.select<ProfileCubit, Object>((cubit) => cubit.state.name)
        : context.select<ProfileCubit, Object>((cubit) => cubit.state.age);
    return div([Component.text('selected:$selected')]);
  }
}


class ReactiveBlocSwitcher extends StatefulComponent {
  const ReactiveBlocSwitcher({
    required this.first,
    required this.second,
    required this.onCreate,
    required this.onListener,
    required this.onConsumerListener,
    super.key,
  });

  final CounterCubit first;
  final CounterCubit second;
  final void Function(ReactiveBlocSwitcherState state) onCreate;
  final void Function(int state) onListener;
  final void Function(int state) onConsumerListener;

  @override
  State<ReactiveBlocSwitcher> createState() => ReactiveBlocSwitcherState();
}

class ReactiveBlocSwitcherState extends State<ReactiveBlocSwitcher> {
  bool useFirst = true;

  @override
  void initState() {
    super.initState();
    component.onCreate(this);
  }

  void switchBloc() => setState(() => useFirst = !useFirst);

  @override
  Component build(BuildContext context) {
    final bloc = useFirst ? component.first : component.second;
    return BlocListener<CounterCubit, int>(
      bloc: bloc,
      listener: (context, state) => component.onListener(state),
      child: div([
        BlocConsumer<CounterCubit, int>(
          bloc: bloc,
          listener: (context, state) => component.onConsumerListener(state),
          builder: (context, state) =>
              span([Component.text('consumer:$state')]),
        ),
        BlocSelector<CounterCubit, int, int>(
          bloc: bloc,
          selector: (state) => state * 2,
          builder: (context, state) =>
              span([Component.text('selector:$state')]),
        ),
      ]),
    );
  }
}

class SelectorCallbackSwitcher extends StatefulComponent {
  const SelectorCallbackSwitcher({required this.cubit, required this.onCreate, super.key});

  final CounterCubit cubit;
  final void Function(SelectorCallbackSwitcherState state) onCreate;

  @override
  State<SelectorCallbackSwitcher> createState() => SelectorCallbackSwitcherState();
}

class SelectorCallbackSwitcherState extends State<SelectorCallbackSwitcher> {
  bool doubleValue = true;

  @override
  void initState() {
    super.initState();
    component.onCreate(this);
  }

  void useTriple() => setState(() => doubleValue = false);

  @override
  Component build(BuildContext context) {
    return BlocSelector<CounterCubit, int, int>(
      bloc: component.cubit,
      selector: doubleValue ? (state) => state * 2 : (state) => state * 3,
      builder: (context, value) =>
          div([Component.text('callback-selector:$value')]),
    );
  }
}

class PredicateSwitcher extends StatefulComponent {
  const PredicateSwitcher({
    required this.cubit,
    required this.onCreate,
    required this.onListen,
    super.key,
  });

  final CounterCubit cubit;
  final void Function(PredicateSwitcherState state) onCreate;
  final void Function(int state) onListen;

  @override
  State<PredicateSwitcher> createState() => PredicateSwitcherState();
}

class PredicateSwitcherState extends State<PredicateSwitcher> {
  bool allow = false;

  @override
  void initState() {
    super.initState();
    component.onCreate(this);
  }

  void enable() => setState(() => allow = true);

  @override
  Component build(BuildContext context) {
    return BlocListener<CounterCubit, int>(
      bloc: component.cubit,
      listenWhen: (previous, current) => allow,
      listener: (context, state) => component.onListen(state),
      child: BlocBuilder<CounterCubit, int>(
        bloc: component.cubit,
        buildWhen: (previous, current) => allow,
        builder: (context, state) =>
            div([Component.text('predicate:$state')]),
      ),
    );
  }
}

void main() {
  setUp(() => setIsClientForTesting(true));
  tearDown(() => resetIsClientForTesting());

  group('flutter_bloc API parity', () {
    testComponents('BlocProvider is lazy by default', (tester) async {
      var createCount = 0;

      tester.pumpComponent(
        BlocProvider<CounterCubit>(
          create: (_) {
            createCount++;
            return CounterCubit();
          },
          child: const Component.empty(),
        ),
      );

      expect(createCount, 0);
    });

    testComponents('BlocProvider lazy false creates immediately', (
      tester,
    ) async {
      var createCount = 0;
      CounterCubit? cubit;

      tester.pumpComponent(
        BlocProvider<CounterCubit>(
          lazy: false,
          create: (_) {
            createCount++;
            return cubit = CounterCubit();
          },
          child: const Component.empty(),
        ),
      );

      expect(createCount, 1);
      addTearDown(() async {
        if (cubit != null && !cubit!.isClosed) await cubit!.close();
      });
    });

    testComponents('RepositoryProvider is lazy and supports dispose', (
      tester,
    ) async {
      var createCount = 0;
      DisposableRepository? repository;

      tester.pumpComponent(
        RepositoryProvider<DisposableRepository>(
          create: (_) {
            createCount++;
            return repository = DisposableRepository();
          },
          dispose: (value) => value.dispose(),
          child: Builder(
            builder: (context) {
              final value = context.read<DisposableRepository>();
              return div([Component.text('${value.disposed}')]);
            },
          ),
        ),
      );

      expect(createCount, 1);
      expect(repository!.disposed, isFalse);

      tester.pumpComponent(const Component.empty());
      await tester.pump();

      expect(repository!.disposed, isTrue);
    });

    testComponents('nullable read returns null when provider is absent', (
      tester,
    ) async {
      tester.pumpComponent(
        Builder(
          builder: (context) {
            final value = context.read<DisposableRepository?>();
            return div([Component.text('missing:${value == null}')]);
          },
        ),
      );

      expect(find.text('missing:true'), findsOneComponent);
    });

    testComponents('nullable watch and select work without a provider', (
      tester,
    ) async {
      tester.pumpComponent(
        Builder(
          builder: (context) {
            final watched = context.watch<DisposableRepository?>();
            final missing = context.select<DisposableRepository?, bool>(
              (value) => value == null,
            );
            return div([
              Component.text('optional:${watched == null && missing}'),
            ]);
          },
        ),
      );

      expect(find.text('optional:true'), findsOneComponent);
    });

    testComponents('nullable read finds a non-nullable provider', (
      tester,
    ) async {
      final repository = DisposableRepository();

      tester.pumpComponent(
        RepositoryProvider<DisposableRepository>.value(
          value: repository,
          child: Builder(
            builder: (context) {
              final value = context.read<DisposableRepository?>();
              return div([
                Component.text('nullable-same:${identical(value, repository)}'),
              ]);
            },
          ),
        ),
      );

      expect(find.text('nullable-same:true'), findsOneComponent);
    });

    testComponents('context.read supports repositories', (tester) async {
      final repository = DisposableRepository();

      tester.pumpComponent(
        RepositoryProvider<DisposableRepository>.value(
          value: repository,
          child: Builder(
            builder: (context) {
              final read = context.read<DisposableRepository>();
              return div([
                Component.text('same:${identical(read, repository)}'),
              ]);
            },
          ),
        ),
      );

      expect(find.text('same:true'), findsOneComponent);
    });

    testComponents('context.select skips unchanged selected values', (
      tester,
    ) async {
      final cubit = ProfileCubit();
      addTearDown(cubit.close);
      var buildCount = 0;

      tester.pumpComponent(
        BlocProvider<ProfileCubit>.value(
          value: cubit,
          child: Builder(
            builder: (context) {
              buildCount++;
              final name = context.select<ProfileCubit, String>(
                (value) => value.state.name,
              );
              return div([Component.text(name)]);
            },
          ),
        ),
      );

      buildCount = 0;
      cubit.birthday();
      await tester.pump();
      expect(buildCount, 0);

      cubit.rename('Bob');
      await tester.pump();
      expect(buildCount, 1);
      expect(find.text('Bob'), findsOneComponent);
    });

    testComponents('context.select uses deep collection equality', (
      tester,
    ) async {
      final cubit = ListCubit();
      addTearDown(cubit.close);
      var buildCount = 0;

      tester.pumpComponent(
        BlocProvider<ListCubit>.value(
          value: cubit,
          child: Builder(
            builder: (context) {
              buildCount++;
              final values = context.select<ListCubit, List<int>>(
                (value) => List<int>.of(value.state),
              );
              return div([Component.text('items:${values.join(',')}')]);
            },
          ),
        ),
      );

      buildCount = 0;
      cubit.emitEquivalent();
      await tester.pump();
      expect(buildCount, 0);

      cubit.append(4);
      await tester.pump();
      expect(buildCount, 1);
      expect(find.text('items:1,2,3,4'), findsOneComponent);
    });

    testComponents('context.select replaces dynamic selector dependencies', (
      tester,
    ) async {
      final cubit = ProfileCubit();
      addTearDown(cubit.close);
      SelectorSwitcherState? state;
      var buildCount = 0;

      tester.pumpComponent(
        BlocProvider<ProfileCubit>.value(
          value: cubit,
          child: SelectorSwitcher(
            onCreate: (value) => state = value,
            onBuild: () => buildCount++,
          ),
        ),
      );

      expect(find.text('selected:Alice'), findsOneComponent);
      state!.selectAge();
      await tester.pump();
      expect(find.text('selected:30'), findsOneComponent);

      buildCount = 0;
      cubit.rename('Bob');
      await tester.pump();
      expect(buildCount, 0);

      cubit.birthday();
      await tester.pump();
      expect(buildCount, 1);
      expect(find.text('selected:31'), findsOneComponent);
    });

    testComponents('BlocBuilder switches implicit provider instances', (
      tester,
    ) async {
      final first = CounterCubit(1);
      final second = CounterCubit(10);
      addTearDown(first.close);
      addTearDown(second.close);
      ProviderSwitcherState? state;

      tester.pumpComponent(
        ProviderSwitcher(
          first: first,
          second: second,
          onCreate: (value) => state = value,
        ),
      );

      expect(find.text('value:1'), findsOneComponent);
      state!.switchBloc();
      await tester.pump();
      expect(find.text('value:10'), findsOneComponent);

      first.increment();
      await tester.pump();
      expect(find.text('value:10'), findsOneComponent);

      second.increment();
      await tester.pump();
      expect(find.text('value:11'), findsOneComponent);
    });

    testComponents('BlocBuilder switches explicit bloc instances', (
      tester,
    ) async {
      final first = CounterCubit(2);
      final second = CounterCubit(20);
      addTearDown(first.close);
      addTearDown(second.close);
      ExplicitBlocSwitcherState? state;

      tester.pumpComponent(
        ExplicitBlocSwitcher(
          first: first,
          second: second,
          onCreate: (value) => state = value,
        ),
      );

      expect(find.text('explicit:2'), findsOneComponent);
      state!.switchBloc();
      await tester.pump();
      expect(find.text('explicit:20'), findsOneComponent);

      first.increment();
      await tester.pump();
      expect(find.text('explicit:20'), findsOneComponent);

      second.increment();
      await tester.pump();
      expect(find.text('explicit:21'), findsOneComponent);
    });

    testComponents(
      'listener consumer and selector switch explicit bloc instances',
      (tester) async {
        final first = CounterCubit(3);
        final second = CounterCubit(30);
        addTearDown(first.close);
        addTearDown(second.close);
        ReactiveBlocSwitcherState? state;
        final listenerStates = <int>[];
        final consumerStates = <int>[];

        tester.pumpComponent(
          ReactiveBlocSwitcher(
            first: first,
            second: second,
            onCreate: (value) => state = value,
            onListener: listenerStates.add,
            onConsumerListener: consumerStates.add,
          ),
        );

        expect(find.text('consumer:3'), findsOneComponent);
        expect(find.text('selector:6'), findsOneComponent);

        state!.switchBloc();
        await tester.pump();
        expect(find.text('consumer:30'), findsOneComponent);
        expect(find.text('selector:60'), findsOneComponent);

        first.increment();
        await tester.pump();
        expect(listenerStates, isEmpty);
        expect(consumerStates, isEmpty);
        expect(find.text('consumer:30'), findsOneComponent);

        second.increment();
        await tester.pump();
        expect(listenerStates, [31]);
        expect(consumerStates, [31]);
        expect(find.text('consumer:31'), findsOneComponent);
        expect(find.text('selector:62'), findsOneComponent);
      },
    );

    testComponents('BlocSelector recomputes when selector callback changes', (
      tester,
    ) async {
      final cubit = CounterCubit(4);
      addTearDown(cubit.close);
      SelectorCallbackSwitcherState? state;

      tester.pumpComponent(
        SelectorCallbackSwitcher(
          cubit: cubit,
          onCreate: (value) => state = value,
        ),
      );

      expect(find.text('callback-selector:8'), findsOneComponent);
      state!.useTriple();
      await tester.pump();
      expect(find.text('callback-selector:12'), findsOneComponent);
    });

    testComponents('updated buildWhen and listenWhen callbacks are used', (
      tester,
    ) async {
      final cubit = CounterCubit();
      addTearDown(cubit.close);
      PredicateSwitcherState? state;
      final listened = <int>[];

      tester.pumpComponent(
        PredicateSwitcher(
          cubit: cubit,
          onCreate: (value) => state = value,
          onListen: listened.add,
        ),
      );

      cubit.increment();
      await tester.pump();
      expect(find.text('predicate:0'), findsOneComponent);
      expect(listened, isEmpty);

      state!.enable();
      await tester.pump();
      cubit.increment();
      await tester.pump();
      expect(find.text('predicate:2'), findsOneComponent);
      expect(listened, [2]);
    });

    testComponents('BlocListener child is optional in MultiBlocListener', (
      tester,
    ) async {
      final cubit = CounterCubit();
      addTearDown(cubit.close);
      final states = <int>[];

      tester.pumpComponent(
        BlocProvider<CounterCubit>.value(
          value: cubit,
          child: MultiBlocListener(
            listeners: [
              BlocListener<CounterCubit, int>(
                listener: (context, state) => states.add(state),
              ),
            ],
            child: const div([Component.text('child')]),
          ),
        ),
      );

      cubit.increment();
      await tester.pump();

      expect(states, [1]);
      expect(find.text('child'), findsOneComponent);
    });

    testComponents('BlocProvider.of supports listen true', (tester) async {
      final cubit = CounterCubit();
      addTearDown(cubit.close);
      var buildCount = 0;

      tester.pumpComponent(
        BlocProvider<CounterCubit>.value(
          value: cubit,
          child: Builder(
            builder: (context) {
              buildCount++;
              final value = BlocProvider.of<CounterCubit>(
                context,
                listen: true,
              );
              return div([Component.text('listened:${value.state}')]);
            },
          ),
        ),
      );

      buildCount = 0;
      cubit.increment();
      await tester.pump();

      expect(buildCount, 1);
      expect(find.text('listened:1'), findsOneComponent);
    });
  });
}
