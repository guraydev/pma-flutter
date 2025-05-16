import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static String? _graphqlApiUrl;

  static Future<void> load() async {
    try {
      await dotenv.load(fileName: ".env");
      _graphqlApiUrl = dotenv.env['GRAPHQL_API_URL'];

      if (_graphqlApiUrl == null) {
        // Fallback or critical error if not set
        print('WARNING: GRAPHQL_API_URL not found in .env file.');
        // Potentially use a default or throw an error if it's critical
        _graphqlApiUrl = 'http://localhost:3001/graphql'; // Default fallback
      }
    } catch (e) {
      print('Error loading .env file: $e');
      // Fallback if .env loading fails
      _graphqlApiUrl = 'http://localhost:3001/graphql'; // Default fallback
    }
  }

  static String get graphqlApiUrl {
    if (_graphqlApiUrl == null) {
      // This should not happen if load() is called before accessing.
      // Consider throwing an error or having a non-nullable default.
      print('CRITICAL: graphqlApiUrl accessed before AppConfig.load() or .env is misconfigured.');
      return 'http://localhost:3001/graphql'; // Last resort fallback
    }
    return _graphqlApiUrl!;
  }
}