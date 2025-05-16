import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/app.dart';
import 'package:frontend/core/config/app_config.dart';
import 'package:frontend/core/api/graphql_client.dart'; // Import initializeHive

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await AppConfig.load();

  // Initialize Hive for GraphQL caching
  await initializeHive(); 

  // Initialize other services here if needed
  // e.g., SharedPreferences instance

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}