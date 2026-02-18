import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_bloc/jaspr_bloc.dart';
import 'package:jaspr_test/jaspr_test.dart';

// ---------------------------------------------------------------------------
// Test doubles
// ---------------------------------------------------------------------------

/// A simple test repository that tracks its state for inspection.
class UserRepository {
  final String name;

  const UserRepository({this.name = 'users'});
}

/// A second distinct test repository.
class AuthRepository {
  final String name;

  const AuthRepository({this.name = 'auth'});
}

/// A component that reads [UserRepository] and renders its name.
class UserReaderComponent extends StatelessComponent {
  const UserReaderComponent({super.key});

  @override
  Component build(BuildContext context) {
    final repo = RepositoryProvider.of<UserRepository>(context);
    return Component.text('repo:${repo.name}');
  }
}

/// A component that reads both repositories and renders their names.
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

/// Captures a repository reference on first build for lifecycle inspection.
class RepoCapture<T> extends StatefulComponent {
  final void Function(T repo) onCapture;

  const RepoCapture({required this.onCapture, super.key});

  @override
  State<RepoCapture<T>> createState() => _RepoCaptureState<T>();
}

class _RepoCaptureState<T> extends State<RepoCapture<T>> {
  bool _captured = false;

  @override
  Component build(BuildContext context) {
    if (!_captured) {
      _captured = true;
      component.onCapture(RepositoryProvider.of<T>(context));
    }
    return const div([]);
  }
}

/// A parent component that conditionally shows or hides its child.
///
/// Used to trigger the dispose lifecycle on nested components via Jaspr's
/// reconciliation.
class ConditionalWrapper extends StatefulComponent {
  final Component child;
  final void Function(ConditionalWrapperState state) onCreate;

  const ConditionalWrapper({
    required this.child,
    required this.onCreate,
    super.key,
  });

  @override
  State<ConditionalWrapper> createState() => ConditionalWrapperState();
}

class ConditionalWrapperState extends State<ConditionalWrapper> {
  bool _visible = true;

  /// Hides the child component, triggering dispose on its subtree.
  void hide() {
    setState(() {
      _visible = false;
    });
  }

  @override
  void initState() {
    super.initState();
    component.onCreate(this);
  }

  @override
  Component build(BuildContext context) {
    if (_visible) {
      return component.child;
    }
    return const div([]);
  }
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('RepositoryProvider', () {
    testComponents('repository is accessible from child context', (
      tester,
    ) async {
      tester.pumpComponent(
        RepositoryProvider<UserRepository>(
          create: (_) => const UserRepository(name: 'users'),
          child: const UserReaderComponent(),
        ),
      );

      expect(find.text('repo:users'), findsOneComponent);
    });

    testComponents('repository is accessible from deeply nested child', (
      tester,
    ) async {
      tester.pumpComponent(
        RepositoryProvider<UserRepository>(
          create: (_) => const UserRepository(name: 'nested'),
          child: const div([
            div([
              div([UserReaderComponent()]),
            ]),
          ]),
        ),
      );

      expect(find.text('repo:nested'), findsOneComponent);
    });

    testComponents('create constructor does not close repository on dispose', (
      tester,
    ) async {
      var createCallCount = 0;
      ConditionalWrapperState? wrapperState;
      UserRepository? capturedRepo;

      tester.pumpComponent(
        ConditionalWrapper(
          onCreate: (state) {
            wrapperState = state;
          },
          child: RepositoryProvider<UserRepository>(
            create: (_) {
              createCallCount++;
              return const UserRepository(name: 'tracked');
            },
            child: RepoCapture<UserRepository>(
              onCapture: (repo) {
                capturedRepo = repo;
              },
            ),
          ),
        ),
      );

      expect(createCallCount, equals(1));
      expect(capturedRepo, isNotNull);
      expect(capturedRepo!.name, equals('tracked'));

      // Dispose the provider — repository should NOT be closed/nullified.
      wrapperState!.hide();
      await tester.pump();

      // Repository instance is still intact after dispose.
      expect(capturedRepo!.name, equals('tracked'));
    });

    testComponents('value constructor provides existing instance', (
      tester,
    ) async {
      const existing = UserRepository(name: 'existing');
      UserRepository? capturedRepo;
      ConditionalWrapperState? wrapperState;

      tester.pumpComponent(
        ConditionalWrapper(
          onCreate: (state) {
            wrapperState = state;
          },
          child: RepositoryProvider<UserRepository>.value(
            value: existing,
            child: RepoCapture<UserRepository>(
              onCapture: (repo) {
                capturedRepo = repo;
              },
            ),
          ),
        ),
      );

      expect(capturedRepo, same(existing));

      // Dispose — the externally created instance is unaffected.
      wrapperState!.hide();
      await tester.pump();

      expect(capturedRepo!.name, equals('existing'));
    });

    testComponents('of<T>() throws when no provider found', (tester) async {
      late Object? caughtError;

      tester.pumpComponent(
        Builder(
          builder: (context) {
            try {
              RepositoryProvider.of<UserRepository>(context);
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
}
