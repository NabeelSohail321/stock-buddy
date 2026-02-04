import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants.dart';

class UserService {
  final String token;

  UserService({required this.token});

  // Get all users
  Future<List<dynamic>> getUsers() async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/users'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to fetch users: ${response.statusCode}');
    }
  }

  // Create user
  Future<Map<String, dynamic>> createUser({
    required String email,
    required String password,
    required String name,
    required String role,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/users'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'email': email,
        'password': password,
        'name': name,
        'role': role,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to create user: ${response.statusCode}');
    }
  }

  // Update user
  Future<Map<String, dynamic>> updateUser({
    required String userId,
    required String name,
    required String role,
    required bool isActive,
  }) async {
    final response = await http.put(
      Uri.parse('${ApiConstants.baseUrl}/users/$userId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'name': name,
        'role': role,
        'isActive': isActive,
      }),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to update user: ${response.statusCode}');
    }
  }

  // Reset user password
  Future<Map<String, dynamic>> resetUserPassword({
    required String userId,
    required String newPassword,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/users/$userId/reset-password'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'newPassword': newPassword,
      }),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to reset password: ${response.statusCode}');
    }
  }
}