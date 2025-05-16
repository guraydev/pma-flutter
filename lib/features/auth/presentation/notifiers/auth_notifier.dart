import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/auth/data/repositories/auth_repository.dart';
import 'package:frontend/features/auth/presentation/state/auth_state.dart';
import 'package:frontend/core/utils/shared_preferences_service.dart';
import 'package:frontend/features/auth/domain/entities/user_entity.dart';

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _authRepository;
  final SharedPreferencesService _sharedPreferencesService;
  // For GraphQLClient token refresh, AuthLink's getToken should dynamically fetch the token
  // from SharedPreferencesService when AuthNotifier updates it.

  AuthNotifier(this._authRepository, this._sharedPreferencesService) : super(const AuthState.initial()) {
    _checkInitialAuthStatus();
  }

  Future<void> _checkInitialAuthStatus() async {
    state = const AuthState.loading();
    try {
      final token = await _sharedPreferencesService.getAuthToken();
      if (token != null && token.isNotEmpty) {
        // Token exists, try to fetch user details to validate it
        print("Token found, attempting to fetch user details...");
        final UserEntity? user = await _authRepository.getMe(); // Call the new method
        if (user != null) {
          print("User details fetched successfully: ${user.email}");
          state = AuthState.authenticated(user: user);
        } else {
          // Token was invalid or user not found
          print("Failed to fetch user details with token, token might be invalid.");
          await _sharedPreferencesService.removeAuthToken(); // Clear invalid token
          state = const AuthState.unauthenticated();
        }
      } else {
        print("No token found in storage.");
        state = const AuthState.unauthenticated();
      }
    } catch (e) {
      // This catch is for errors during token read or if getMe throws unexpectedly
      print("Error during _checkInitialAuthStatus: $e");
      await _sharedPreferencesService.removeAuthToken(); // Clear token on error too
      state = const AuthState.unauthenticated(); // Default to unauthenticated on any error
    }
  }

  Future<void> login(String email, String password) async {
    state = const AuthState.loading();
    try {
      final (user, token) = await _authRepository.login(email, password);
      if (user != null && token != null) {
        await _sharedPreferencesService.setAuthToken(token);
        // The GraphQL client's AuthLink will pick up the new token on its next request.
        state = AuthState.authenticated(user: user);
      } else {
        state = const AuthState.error('Login failed: Invalid response from server.');
      }
    } catch (e) {
      state = AuthState.error(e.toString());
    }
  }

  Future<void> register({
    required String email,
    required String password,
    String? firstName,
    String? lastName,
  }) async {
    state = const AuthState.loading();
    try {
      final user = await _authRepository.register(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
      );
      // After successful registration, transition to unauthenticated to prompt login.
      // Or, you could implement auto-login here.
      state = const AuthState.unauthenticated(); 
      print('Registration successful for ${user.email}. Please login.');
    } catch (e) {
      state = AuthState.error(e.toString());
    }
  }

  Future<void> logout() async {
    state = const AuthState.loading();
    await _sharedPreferencesService.removeAuthToken();
    // Inform GraphQL client that token is gone (AuthLink will fetch null)
    state = const AuthState.unauthenticated();
  }
}

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  final prefsService = ref.watch(sharedPreferencesServiceProvider);
  return AuthNotifier(authRepository, prefsService);
});