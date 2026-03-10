import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_bloc/jaspr_bloc.dart';
import 'package:jaspr_test/jaspr_test.dart';

// ---------------------------------------------------------------------------
// Test doubles
// ---------------------------------------------------------------------------

/// A simple test repository.
class UserRepository {
  final String name;

  const UserRepository({this.name = 'users'});
}

/// A second distinct test repository.
class AuthRepository {
  final String name;

  const AuthRepository({this.name = 'auth'});
}

/// A third distinct test repository.
class ProductRepository {
  final String name;

  const ProductRepository({this.name = 'products'});
}

/// A simple test cubit for mixed-provider tests.
class CounterCubit extends Cubit<int> {
  CounterCubit() : super(0);
}

/// A component that reads all three repositories and renders their names.
class ThreeRepoReaderComponent extends StatelessComponent {
  const ThreeRepoReaderComponent({super.key});

  @override
  Component build(BuildContext context) {
    final user = RepositoryProvider.of<UserRepository>(context);
    final auth = RepositoryProvider.of<AuthRepository>(context);
    final product = RepositoryProvider.of<ProductRepository>(context);
    return div([
      Component.text('user:${user.name}'),
      Component.text('auth:${auth.name}'),
      Component.text('product:${product.name}'),
    ]);
  }
}

/// A component that reads two repositories and renders their names.
class TwoRepoReaderComponent extends StatelessComponent {
  const TwoRepoReaderComponent({super.key});

  @override
  Component build(BuildContext context) {
    final user = RepositoryProvider.of<UserRepository>(context);
    final auth = RepositoryProvider.of<AuthRepository>(context);
    return div([
      Component.text('user:${user.name}'),
      Component.text('auth:${auth.name}'),
    ]);
  }
}

/// A component that reads one repository and one bloc.
class MixedReaderComponent extends StatelessComponent {
  const MixedReaderComponent({super.key});

  @override
  Component build(BuildContext context) {
    final repo = RepositoryProvider.of<UserRepository>(context);
    final counter = BlocProvider.of<CounterCubit>(context);
    return div([
      Component.text('repo:${repo.name}'),
      Component.text('counter:${counter.state}'),
    ]);
  }
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('MultiRepositoryProvider', () {
    testComponents('all repositories from the list are accessible from child', (
      tester,
    ) async {
      tester.pumpComponent(
        MultiRepositoryProvider(
          providers: [
            RepositoryProvider<UserRepository>(
              create: (_) => const UserRepository(name: 'users'),
            ),
            RepositoryProvider<AuthRepository>(
              create: (_) => const AuthRepository(name: 'auth'),
            ),
            RepositoryProvider<ProductRepository>(
              create: (_) => const ProductRepository(name: 'products'),
            ),
          ],
          child: const ThreeRepoReaderComponent(),
        ),
      );

      expect(find.text('user:users'), findsOneComponent);
      expect(find.text('auth:auth'), findsOneComponent);
      expect(find.text('product:products'), findsOneComponent);
    });

    testComponents(
      'all repositories are accessible from a deeply nested child',
      (tester) async {
        tester.pumpComponent(
          MultiRepositoryProvider(
            providers: [
              RepositoryProvider<UserRepository>(
                create: (_) => const UserRepository(name: 'users'),
              ),
              RepositoryProvider<AuthRepository>(
                create: (_) => const AuthRepository(name: 'auth'),
              ),
            ],
            child: const div([
              div([
                div([TwoRepoReaderComponent()]),
              ]),
            ]),
          ),
        );

        expect(find.text('user:users'), findsOneComponent);
        expect(find.text('auth:auth'), findsOneComponent);
      },
    );

    testComponents(
      'nesting works correctly with mixed bloc and repository providers',
      (tester) async {
        tester.pumpComponent(
          BlocProvider<CounterCubit>(
            create: (_) => CounterCubit(),
            child: MultiRepositoryProvider(
              providers: [
                RepositoryProvider<UserRepository>(
                  create: (_) => const UserRepository(name: 'users'),
                ),
              ],
              child: const MixedReaderComponent(),
            ),
          ),
        );

        expect(find.text('repo:users'), findsOneComponent);
        expect(find.text('counter:0'), findsOneComponent);
      },
    );

    testComponents('value constructor providers are accessible from child', (
      tester,
    ) async {
      const userRepo = UserRepository(name: 'value-user');
      const authRepo = AuthRepository(name: 'value-auth');

      tester.pumpComponent(
        const MultiRepositoryProvider(
          providers: [
            RepositoryProvider<UserRepository>.value(value: userRepo),
            RepositoryProvider<AuthRepository>.value(value: authRepo),
          ],
          child: TwoRepoReaderComponent(),
        ),
      );

      expect(find.text('user:value-user'), findsOneComponent);
      expect(find.text('auth:value-auth'), findsOneComponent);
    });

    testComponents('provider ordering does not affect access', (tester) async {
      // Reversed order — both still accessible regardless of position.
      tester.pumpComponent(
        MultiRepositoryProvider(
          providers: [
            RepositoryProvider<AuthRepository>(
              create: (_) => const AuthRepository(name: 'auth'),
            ),
            RepositoryProvider<UserRepository>(
              create: (_) => const UserRepository(name: 'users'),
            ),
          ],
          child: Builder(
            builder: (context) {
              final user = RepositoryProvider.of<UserRepository>(context);
              final auth = RepositoryProvider.of<AuthRepository>(context);
              return div([
                Component.text('user:${user.name}'),
                Component.text('auth:${auth.name}'),
              ]);
            },
          ),
        ),
      );

      expect(find.text('user:users'), findsOneComponent);
      expect(find.text('auth:auth'), findsOneComponent);
    });
  });
}
