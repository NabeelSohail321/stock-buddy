import 'dart:convert';
import 'package:http/http.dart' as http;

import '../core/constants.dart';
import '../models/auth_response.dart';


class ApiService {
  final http.Client client;

  ApiService({required this.client});

  Future<AuthResponse> register({
    required String email,
    required String password,
    required String name,
    String? deviceToken, // Add optional deviceToken parameter
  }) async {
    try {
      // Create the base request body
      final Map<String, dynamic> requestBody = {
        'email': email,
        'password': password,
        'name': name,
      };

      // Add device token only if it's provided (mobile devices)
      if (deviceToken != null && deviceToken.isNotEmpty) {
        requestBody['noti'] = deviceToken;
        print('Including device token in registration request');
      }

      final response = await client.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.register}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      ).timeout(ApiConstants.connectTimeout);

      print('Register Response Status: ${response.statusCode}');
      print('Register Response Body: ${response.body}');

      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        return AuthResponse.fromJson(responseData);
      } else {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        final errorMessage = errorData['message'] ?? 'Registration failed';
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('Register Error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> verifyToken(String token) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/auth/verify-token'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 401) {
      final errorResponse = jsonDecode(response.body);
      throw Exception(errorResponse['error'] ?? 'Invalid token');
    } else {
      throw Exception('Failed to verify token: ${response.statusCode}');
    }
  }
  Future<AuthResponse> login({
    required String email,
    required String password,
    String? deviceToken, // Add optional deviceToken parameter
  }) async {
    try {
      // Create the base request body
      final Map<String, dynamic> requestBody = {
        'email': email,
        'password': password,
      };

      // Add device token only if it's provided (mobile devices)
      if (deviceToken != null && deviceToken.isNotEmpty) {
        requestBody['noti'] = deviceToken;
        print('Including device token in login request');
      }

      final response = await client.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.login}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      ).timeout(ApiConstants.connectTimeout);

      print('Login Response Status: ${response.statusCode}');
      print('Login Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        return AuthResponse.fromJson(responseData);
      } else {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        final errorMessage = errorData['message'] ?? 'Login failed';
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('Login Error: $e');
      rethrow;
    }
  }
}