import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../core/app_exception.dart';
import '../core/constants.dart';

class UserService {
  final String token;

  UserService({required this.token});

  Map<String, String> get _headers => {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

  Future<dynamic> _send(Future<http.Response> Function() fn) async {
    try {
      final response = await fn().timeout(ApiConstants.connectTimeout);
      debugPrint('[UserService] ${response.statusCode}');
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return response.body.isNotEmpty ? json.decode(response.body) : null;
      }
      final body = _parseBody(response.body);
      final message = body['message'] ?? body['error'] ?? 'Error ${response.statusCode}';
      _throwForStatus(response.statusCode, message);
    } on SocketException {
      throw const NetworkException();
    } on TimeoutException {
      throw const RequestTimeoutException();
    } on AppException {
      rethrow;
    } catch (e) {
      debugPrint('[UserService] unexpected: $e');
      throw AppException('An unexpected error occurred. Please try again.');
    }
  }

  Map<String, dynamic> _parseBody(String body) {
    try {
      return json.decode(body) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  void _throwForStatus(int code, String message) {
    switch (code) {
      case 401:
        throw AuthException(message);
      case 403:
        throw ForbiddenException(message);
      case 404:
        throw NotFoundException(message);
      case 422:
        throw ValidationException(message);
      default:
        throw ServerException(message, code);
    }
  }

  Future<List<dynamic>> getUsers() async {
    final result = await _send(
      () => http.get(Uri.parse('${ApiConstants.baseUrl}/users'), headers: _headers),
    );
    return result as List<dynamic>;
  }

  Future<Map<String, dynamic>> createUser({
    required String email,
    required String password,
    required String name,
    required String role,
  }) async {
    final result = await _send(
      () => http.post(
        Uri.parse('${ApiConstants.baseUrl}/users'),
        headers: _headers,
        body: json.encode({
          'email': email,
          'password': password,
          'name': name,
          'role': role,
          'isAuditApproved': role == 'audits',
        }),
      ),
    );
    return result as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateUser({
    required String userId,
    required String name,
    required String role,
    required bool isActive,
  }) async {
    final result = await _send(
      () => http.put(
        Uri.parse('${ApiConstants.baseUrl}/users/$userId'),
        headers: _headers,
        body: json.encode({
          'name': name,
          'role': role,
          'isActive': isActive,
          'isAuditApproved': role == 'audits',
        }),
      ),
    );
    return result as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> resetUserPassword({
    required String userId,
    required String newPassword,
  }) async {
    final result = await _send(
      () => http.post(
        Uri.parse('${ApiConstants.baseUrl}/users/$userId/reset-password'),
        headers: _headers,
        body: json.encode({'newPassword': newPassword}),
      ),
    );
    return result as Map<String, dynamic>;
  }
}
