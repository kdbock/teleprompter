import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/signup_screen.dart';
import '../../features/team/screens/home_screen.dart';
import '../../features/team/screens/create_team_screen.dart';
import '../../features/team/screens/team_detail_screen.dart';
import '../../features/scripts/screens/scripts_screen.dart';
import '../../features/scripts/screens/script_editor_screen.dart';
import '../../features/scripts/screens/script_detail_screen.dart';
import '../../features/prompter/screens/prompter_screen.dart';
import '../../features/prompter/screens/recordings_screen.dart';
import '../../features/prompter/screens/record_with_prompter_v2_screen.dart';

/// Application routing configuration
class AppRouter {
  static const _authRoutes = {'/login', '/signup'};

  static final GoRouter router = GoRouter(
    initialLocation: '/',
    refreshListenable: GoRouterRefreshStream(
      FirebaseAuth.instance.authStateChanges(),
    ),
    redirect: (context, state) {
      final isLoggedIn = FirebaseAuth.instance.currentUser != null;
      final path = state.uri.path;
      final onAuthRoute = _authRoutes.contains(path);

      if (!isLoggedIn && !onAuthRoute) {
        return '/login';
      }
      if (isLoggedIn && (onAuthRoute || path == '/')) {
        return '/home';
      }
      if (!isLoggedIn && path == '/') {
        return '/login';
      }
      return null;
    },
    routes: [
      // Auth routes
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        name: 'signup',
        builder: (context, state) => const SignupScreen(),
      ),

      // Home route
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),

      // Team routes
      GoRoute(
        path: '/create-team',
        name: 'create-team',
        builder: (context, state) => const CreateTeamScreen(),
      ),
      GoRoute(
        path: '/team/:id',
        name: 'team-detail',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return TeamDetailScreen(teamId: id);
        },
      ),

      // Script routes
      GoRoute(
        path: '/scripts',
        name: 'scripts',
        builder: (context, state) => const ScriptsScreen(),
      ),
      GoRoute(
        path: '/scripts/new',
        name: 'script-new',
        builder: (context, state) => const ScriptEditorScreen(),
      ),
      GoRoute(
        path: '/scripts/:id',
        name: 'script-detail',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ScriptDetailScreen(scriptId: id);
        },
      ),
      GoRoute(
        path: '/scripts/:id/edit',
        name: 'script-edit',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ScriptEditorScreen(scriptId: id);
        },
      ),

      // Prompter routes
      GoRoute(
        path: '/prompter/:id',
        name: 'prompter',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return PrompterScreen(scriptId: id);
        },
      ),
      GoRoute(
        path: '/recordings',
        name: 'recordings',
        builder: (context, state) => const RecordingsScreen(),
      ),
      GoRoute(
        path: '/record/:id',
        name: 'record-with-prompter',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return RecordWithPrompterV2Screen(scriptId: id);
        },
      ),

      // Team management routes will be added here
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.uri}'),
      ),
    ),
  );
}

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
