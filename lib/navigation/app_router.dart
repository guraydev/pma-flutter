import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/features/home/presentation/screens/home_screen.dart';
import 'package:frontend/features/auth/presentation/screens/login_screen.dart';
import 'package:frontend/features/auth/presentation/screens/register_screen.dart'; // <-- Import RegisterScreen
import 'package:frontend/features/auth/presentation/notifiers/auth_notifier.dart';
import 'package:frontend/features/auth/presentation/state/auth_state.dart';
import 'package:frontend/features/project_management/presentation/screens/project_details_screen.dart';


class PlaceholderSplashScreen extends StatelessWidget {
  const PlaceholderSplashScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(),
        SizedBox(height: 20),
        Text('Loading App... Splash Screen Placeholder'),
      ],
    )));
  }
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final authStateListenable = ValueNotifier<AuthState>(ref.watch(authNotifierProvider));
  ref.listen(authNotifierProvider, (_, next) {
    authStateListenable.value = next;
  });

  return GoRouter(
    initialLocation: '/splash',
    debugLogDiagnostics: true,
    refreshListenable: authStateListenable,
    routes: [
      GoRoute(
        name: 'splash',
        path: '/splash',
        builder: (context, state) => const PlaceholderSplashScreen(),
      ),
      GoRoute(
        name: 'login',
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      // New Route for Registration
      GoRoute(
        name: 'register',
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        name: 'home',
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        name: 'projectDetails',
        path: '/project/:projectId',
        builder: (context, state) {
          final projectId = state.pathParameters['projectId'];
          if (projectId == null) {
            return Scaffold(
              appBar: AppBar(title: const Text('Error')),
              body: const Center(child: Text('Project ID is missing.')),
            );
          }
          return ProjectDetailsScreen(projectId: projectId);
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Page Not Found')),
      body: Center(
        child: Text('Error: ${state.error?.message ?? 'Page not found.'}'),
      ),
    ),
    redirect: (BuildContext context, GoRouterState routerState) {
      final authStateValue = ref.read(authNotifierProvider);
      final currentLocation = routerState.matchedLocation;

      final bool isAuthenticated = authStateValue.maybeWhen(
        authenticated: (_) => true,
        orElse: () => false,
      );
      final bool isInitialOrLoading = authStateValue.maybeWhen(
        initial: () => true,
        loading: () => true,
        orElse: () => false,
      );

      // Public routes that can be accessed regardless of auth state (after initial loading)
      final publicRoutes = ['/login', '/register', '/splash'];

      if (isInitialOrLoading && currentLocation == '/splash') {
        return null; // Stay on splash
      }

      if (isAuthenticated) {
        if (currentLocation == '/login' || currentLocation == '/register' || currentLocation == '/splash') {
          return '/home'; // If authenticated, redirect from auth/splash pages to home
        }
      } else { // Not authenticated
        if (!publicRoutes.contains(currentLocation)) {
          return '/login'; // If not authenticated and not on a public route, redirect to login
        }
      }
      return null;
    },
  );
});