import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:frontend/core/config/app_config.dart';
import 'package:frontend/core/utils/shared_preferences_service.dart';
import 'package:shared_preferences/shared_preferences.dart'; // <-- Add this import

// ... rest of the file content as provided before ...
final graphqlClientProvider = Provider<GraphQLClient>((ref) {
  final HttpLink httpLink = HttpLink(
    AppConfig.graphqlApiUrl,
  );

  final AuthLink authLink = AuthLink(
    getToken: () async {
      try {
        final sharedPrefs = await SharedPreferences.getInstance(); // Now SharedPreferences is known
        final token = sharedPrefs.getString('authToken');
        if (token != null && token.isNotEmpty) {
          print('AuthLink: Using token: Bearer $token');
          return 'Bearer $token';
        }
      } catch (e) {
        print('AuthLink: Error fetching token: $e');
      }
      print('AuthLink: No token found.');
      return null;
    },
  );

  final Link link = authLink.concat(httpLink);

  return GraphQLClient(
    cache: GraphQLCache(store: HiveStore()),
    link: link,
  );
});

final graphqlClientNotifierProvider = Provider<ValueNotifier<GraphQLClient>>((ref) {
  final client = ref.watch(graphqlClientProvider);
  return ValueNotifier(client);
});

Future<void> initializeHive() async {
  await initHiveForFlutter();
}