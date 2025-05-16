import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_entity.freezed.dart';
// We might add @JsonSerializable() if we were fetching this from a REST API and needed fromJson/toJson
// For GraphQL, the codegen will often handle this. For now, a simple Freezed class.

@freezed
class UserEntity with _$UserEntity {
  const factory UserEntity({
    required String id,
    required String email,
    String? firstName,
    String? lastName,
    // Add other relevant fields from your backend's User type
  }) = _UserEntity;
}