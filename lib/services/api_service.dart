import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../core/app_exception.dart';
import '../core/constants.dart';
import '../models/auth_response.dart';

class ApiService {
  final http.Client client;

  ApiService({required this.client});

  Future<AuthResponse> register({
    required String email,
    required String password,
    required String name,
    String? deviceToken,
  }) async {
    try {
      final body = <String, dynamic>{
        'email': email,
        'password': password,
        'name': name,
        if (deviceToken != null && deviceToken.isNotEmpty) 'noti': deviceToken,
      };

      final response = await client
          .post(
            Uri.parse('${ApiConstants.baseUrl}${ApiConstants.register}'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(ApiConstants.connectTimeout);

      if (response.statusCode == 201) {
        return AuthResponse.fromJson(jsonDecode(response.body));
      }
      final msg = _extractMessage(response) ?? 'Registration failed';
      throw ValidationException(msg);
    } on SocketException {
      throw const NetworkException();
    } on TimeoutException {
      throw const RequestTimeoutException();
    } on AppException {
      rethrow;
    } catch (e) {
      debugPrint('[ApiService] register error: $e');
      rethrow;
    }
  }

  Future<AuthResponse> login({
    required String email,
    required String password,
    String? deviceToken,
  }) async {
    try {
      final body = <String, dynamic>{
        'email': email,
        'password': password,
        if (deviceToken != null && deviceToken.isNotEmpty) 'noti': deviceToken,
      };

      final response = await client
          .post(
            Uri.parse('${ApiConstants.baseUrl}${ApiConstants.login}'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(ApiConstants.connectTimeout);

      if (response.statusCode == 200) {
        return AuthResponse.fromJson(jsonDecode(response.body));
      }

      final msg = _extractMessage(response) ?? 'Invalid email or password';
      if (response.statusCode == 401) throw AuthException(msg);
      throw ValidationException(msg);
    } on SocketException {
      throw const NetworkException();
    } on TimeoutException {
      throw const RequestTimeoutException();
    } on AppException {
      rethrow;
    } catch (e) {
      debugPrint('[ApiService] login error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> verifyToken(String token) async {
    try {
      final response = await client
          .post(
            Uri.parse('${ApiConstants.baseUrl}/auth/verify-token'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          )
          .timeout(ApiConstants.connectTimeout);

      if (response.statusCode == 200) return jsonDecode(response.body);
      throw const AuthException();
    } on SocketException {
      throw const NetworkException();
    } on TimeoutException {
      throw const RequestTimeoutException();
    } on AppException {
      rethrow;
    }
  }

  String? _extractMessage(http.Response response) {
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return body['message']?.toString() ?? body['error']?.toString();
    } catch (_) {
      return null;
    }
  }
}
