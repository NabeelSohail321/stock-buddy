import 'user_model.dart';

class AuthResponse {
  final String message;
  final String token;
  final User user;

  AuthResponse({
    required this.message,
    required this.token,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      message: json['message']?.toString() ?? 'Success',
      token: json['token']?.toString() ?? '',
      user: User.fromJson(json['user'] ?? {}), // Handle null user
    );
  }
}