import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../core/app_exception.dart';
import '../core/constants.dart';

class ManagerService {
  final String token;

  ManagerService({required this.token});

  Map<String, String> get _headers => {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

  Future<dynamic> _send(Future<http.Response> Function() fn) async {
    try {
      final response = await fn().timeout(ApiConstants.connectTimeout);
      debugPrint('[ManagerService] ${response.statusCode}');
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
      debugPrint('[ManagerService] unexpected: $e');
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

  Future<List<dynamic>> getManagers({bool includeInactive = false}) async {
    final result = await _send(
      () => http.get(
        Uri.parse('${ApiConstants.baseUrl}/managers').replace(
          queryParameters: includeInactive ? {'includeInactive': 'true'} : null,
        ),
        headers: {'Authorization': 'Bearer $token'},
      ),
    );
    return result as List<dynamic>;
  }

  Future<Map<String, dynamic>> createManager({
    required String name,
    required String email,
    String? phone,
    List<String> assignedLocationIds = const [],
    Map<String, bool> notificationPreferences = const {
      'stock': true,
      'repair': true,
      'disposal': true,
      'transfer': true,
    },
  }) async {
    final result = await _send(
      () => http.post(
        Uri.parse('${ApiConstants.baseUrl}/managers'),
        headers: _headers,
        body: json.encode({
          'name': name,
          'email': email,
          if (phone != null && phone.isNotEmpty) 'phone': phone,
          'assignedLocationIds': assignedLocationIds,
          'notificationPreferences': notificationPreferences,
        }),
      ),
    );
    return result as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateManager({
    required String managerId,
    required String name,
    required String email,
    String? phone,
    List<String> assignedLocationIds = const [],
    Map<String, bool> notificationPreferences = const {
      'stock': true,
      'repair': true,
      'disposal': true,
      'transfer': true,
    },
    bool isActive = true,
  }) async {
    final result = await _send(
      () => http.put(
        Uri.parse('${ApiConstants.baseUrl}/managers/$managerId'),
        headers: _headers,
        body: json.encode({
          'name': name,
          'email': email,
          if (phone != null) 'phone': phone,
          'assignedLocationIds': assignedLocationIds,
          'notificationPreferences': notificationPreferences,
          'isActive': isActive,
        }),
      ),
    );
    return result as Map<String, dynamic>;
  }

  Future<List<dynamic>> getManagersByLocation(String locationId) async {
    try {
      final result = await _send(
        () => http.get(
          Uri.parse('${ApiConstants.baseUrl}/managers/by-location/$locationId'),
          headers: {'Authorization': 'Bearer $token'},
        ),
      );
      return result as List<dynamic>;
    } on AppException {
      return [];
    }
  }
}
