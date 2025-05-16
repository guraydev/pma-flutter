import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _authTokenKey = 'authToken';

class SharedPreferencesService {
  final SharedPreferences _prefs;

  SharedPreferencesService(this._prefs);

  Future<String?>getAuthToken() async {
    return _prefs.getString(_authTokenKey);
  }

  Future<void> setAuthToken(String token) async {
    await _prefs.setString(_authTokenKey, token);
  }

  Future<void> removeAuthToken() async {
    await _prefs.remove(_authTokenKey);
  }
}

// Provider for SharedPreferences instance
final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) async {
  return await SharedPreferences.getInstance();
});

// Provider for SharedPreferencesService
final sharedPreferencesServiceProvider = Provider<SharedPreferencesService>((ref) {
  // Wait for SharedPreferences to be available
  final prefs = ref.watch(sharedPreferencesProvider).asData?.value;
  if (prefs == null) {
    // This should ideally not happen if main waits for SharedPreferences or if app has a loading state
    // For now, we might throw or return a service that indicates it's not ready.
    // A better way is to have the dependent providers handle the AsyncValue from sharedPreferencesProvider.
    throw Exception("SharedPreferences not initialized"); 
  }
  return SharedPreferencesService(prefs);
});

// A simpler provider that directly exposes the token, and can be watched for changes.
// This needs to be a StateNotifierProvider or similar if we want to reactively update UI
// when the token changes programmatically from different parts of the app.
// For now, AuthNotifier will handle reading/writing it.
final authTokenProvider = FutureProvider<String?>((ref) async {
  final prefsService = ref.watch(sharedPreferencesServiceProvider);
  return prefsService.getAuthToken();
});