import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:frontend/core/api/graphql_client.dart';
import 'package:frontend/features/auth/domain/entities/user_entity.dart';

// Import newly generated file for auth operations
import 'package:frontend/core/api/generated/auth.graphql.dart';
// Import the generated file for login/register mutations if they were in a different .graphql file
// For this example, login/register mutations were manually defined.
// If you move them to auth.graphql, you'd use generated types for them too.

// Existing GraphQL Mutation Strings (if not moved to .graphql files and generated)
const String loginMutation = '''
  mutation Login(\$email: String!, \$password: String!) {
    login(loginInput: { email: \$email, password: \$password }) {
      accessToken
      user {
        id
        email
        firstName
        lastName
        isActive 
      }
    }
  }
''';

const String registerMutation = '''
  mutation Register(\$email: String!, \$password: String!, \$firstName: String, \$lastName: String) {
    register(createUserInput: { email: \$email, password: \$password, firstName: \$firstName, lastName: \$lastName }) {
      id
      email
      firstName
      lastName
      isActive
    }
  }
''';


class AuthRepository {
  final GraphQLClient _client;

  AuthRepository(this._client);

  Future<(UserEntity?, String?)> login(String email, String password) async {
    final MutationOptions options = MutationOptions(
      document: gql(loginMutation), // Using raw string, ideally use generated
      variables: <String, dynamic>{
        'email': email,
        'password': password,
      },
    );

    final QueryResult result = await _client.mutate(options);

    if (result.hasException) {
      print('Login Exception: ${result.exception.toString()}');
      throw Exception(result.exception?.graphqlErrors.isNotEmpty == true
          ? result.exception!.graphqlErrors.map((e) => e.message).join(', ')
          : 'Login failed');
    }

    if (result.data != null && result.data!['login'] != null) {
      final loginData = result.data!['login'];
      final userData = loginData['user'];
      final accessToken = loginData['accessToken'] as String;
      
      final userEntity = UserEntity(
        id: userData['id'] as String,
        email: userData['email'] as String,
        firstName: userData['firstName'] as String?,
        lastName: userData['lastName'] as String?,
      );
      return (userEntity, accessToken);
    }
    throw Exception('Login failed: No data received.');
  }

  Future<UserEntity> register({
    required String email,
    required String password,
    String? firstName,
    String? lastName,
  }) async {
    final MutationOptions options = MutationOptions(
      document: gql(registerMutation), // Using raw string, ideally use generated
      variables: <String, dynamic>{
        'email': email,
        'password': password,
        'firstName': firstName,
        'lastName': lastName,
      },
    );

    final QueryResult result = await _client.mutate(options);

    if (result.hasException) {
      print('Registration Exception: ${result.exception.toString()}');
      throw Exception(result.exception?.graphqlErrors.isNotEmpty == true
          ? result.exception!.graphqlErrors.map((e) => e.message).join(', ')
          : 'Registration failed');
    }
    
    if (result.data != null && result.data!['register'] != null) {
      final userData = result.data!['register'];
      return UserEntity(
        id: userData['id'] as String,
        email: userData['email'] as String,
        firstName: userData['firstName'] as String?,
        lastName: userData['lastName'] as String?,
      );
    }
    throw Exception('Registration failed: No data received.');
  }

  // NEW METHOD: Get current authenticated user
  Future<UserEntity?> getMe() async {
    // Use the generated options and variables if available
    // Assuming QueryGetMe and OptionsQueryGetMe are generated in auth.graphql.dart
    final options = OptionsQueryGetMe(); 
    final QueryResult result = await _client.query(options);

    if (result.hasException) {
      // If token is invalid/expired, backend will likely return an auth error
      print('GetMe Exception: ${result.exception.toString()}');
      // Don't throw an exception here that would be treated as a generic error,
      // as a failure here often means "not authenticated" rather than "system error".
      return null; 
    }

    final userData = result.data?['me'];
    if (userData != null) {
      // Map the data (which should be of type QueryGetMe$me) to UserEntity
      // The generated type QueryGetMe$me should have the fields id, email, firstName, lastName.
      return UserEntity(
        id: userData['id'] as String, // Cast based on your GraphQL schema/generated types
        email: userData['email'] as String,
        firstName: userData['firstName'] as String?,
        lastName: userData['lastName'] as String?,
      );
    }
    return null; // No user data found or 'me' field was null
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final client = ref.watch(graphqlClientProvider);
  return AuthRepository(client);
});