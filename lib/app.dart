import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/navigation/app_router.dart';
import 'package:frontend/core/api/graphql_client.dart'; // Import client provider
import 'package:graphql_flutter/graphql_flutter.dart'; // Import GraphQLProvider

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final graphqlClientNotifier = ref.watch(graphqlClientNotifierProvider); // Get the ValueNotifier

    return GraphQLProvider( // Wrap MaterialApp.router with GraphQLProvider
      client: graphqlClientNotifier,
      child: MaterialApp.router(
        title: 'Project Master',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        // darkTheme: AppTheme.darkTheme,
        // themeMode: ThemeMode.system,
        routerConfig: router,
      ),
    );
  }
}