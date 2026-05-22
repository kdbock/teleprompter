import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/signup_screen.dart';
import '../../features/team/screens/home_screen.dart';
import '../../features/team/screens/create_team_screen.dart';
import '../../features/scripts/screens/scripts_screen.dart';
import '../../features/scripts/screens/script_editor_screen.dart';
import '../../features/scripts/screens/script_detail_screen.dart';
import '../../features/prompter/screens/prompter_screen.dart';

/// Application routing configuration
class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/login',
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

      // Redirect root to login
      GoRoute(
        path: '/',
        redirect: (context, state) => '/login',
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
