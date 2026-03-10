import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_bloc/src/repository_inherited.dart';
import 'package:jaspr_test/jaspr_test.dart';

// ---------------------------------------------------------------------------
// Test doubles
// ---------------------------------------------------------------------------

/// A simple test repository.
class UserRepository {
  final String name;

  const UserRepository({this.name = 'users'});
}

/// A component that subscribes to [RepositoryInherited] via [RepositoryInherited.of].
///
/// Using [RepositoryInherited.of] (not [RepositoryInherited.readOf]) registers
/// the component as a dependent so it rebuilds when the inherited value changes.
class SubscribingConsumer extends StatelessComponent {
  const SubscribingConsumer({super.key});

  @override
  Component build(BuildContext context) {
    final repo = RepositoryInherited.of<UserRepository>(context);
    return Component.text('repo:${repo.name}');
  }
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('RepositoryInherited', () {
    group('of<T>', () {
      testComponents('retrieves the repository and subscribes to changes', (
        tester,
      ) async {
        tester.pumpComponent(
          const RepositoryInherited<UserRepository>(
            repository: UserRepository(name: 'test'),
            child: SubscribingConsumer(),
          ),
        );

        expect(find.text('repo:test'), findsOneComponent);
      });

      testComponents('works from a deeply nested descendant context', (
        tester,
      ) async {
        tester.pumpComponent(
          const RepositoryInherited<UserRepository>(
            repository: UserRepository(name: 'deep'),
            child: div([
              div([
                div([SubscribingConsumer()]),
              ]),
            ]),
          ),
        );

        expect(find.text('repo:deep'), findsOneComponent);
      });

      testComponents('throws when no RepositoryInherited found in context', (
        tester,
      ) async {
        late Object? caughtError;

        tester.pumpComponent(
          Builder(
            builder: (context) {
              try {
                RepositoryInherited.of<UserRepository>(context);
              } catch (e) {
                caughtError = e;
              }
              return const div([]);
            },
          ),
        );

        expect(caughtError, isNotNull);
      });
    });

    group('updateShouldNotify', () {
      test('returns true when repository instance changes', () {
        const repoA = UserRepository(name: 'a');
        const repoB = UserRepository(name: 'b');
        const oldInherited = RepositoryInherited<UserRepository>(
          repository: repoA,
          child: div([]),
        );
        const newInherited = RepositoryInherited<UserRepository>(
          repository: repoB,
          child: div([]),
        );

        expect(newInherited.updateShouldNotify(oldInherited), isTrue);
      });

      test('returns false when repository instance is the same', () {
        const repo = UserRepository(name: 'same');
        const oldInherited = RepositoryInherited<UserRepository>(
          repository: repo,
          child: div([]),
        );
        const newInherited = RepositoryInherited<UserRepository>(
          repository: repo,
          child: div([]),
        );

        expect(newInherited.updateShouldNotify(oldInherited), isFalse);
      });
    });
  });
}
