import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../core/app_exception.dart';
import '../core/constants.dart';
import '../models/location_model.dart';

class LocationService {
  final String token;

  LocationService({required this.token});

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  Future<dynamic> _send(Future<http.Response> Function() fn) async {
    try {
      final response = await fn().timeout(ApiConstants.connectTimeout);
      debugPrint('[LocationService] ${response.statusCode}');
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
      debugPrint('[LocationService] unexpected: $e');
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

  Future<Location> createLocation({
    required String name,
    String? address,
  }) async {
    final result = await _send(
      () => http.post(
        Uri.parse('${ApiConstants.baseUrl}/locations'),
        headers: _headers,
        body: json.encode({'name': name, if (address != null) 'address': address}),
      ),
    );
    final data = result as Map<String, dynamic>;
    return Location.fromJson(data['location'] ?? data);
  }

  Future<List<Location>> getLocations() async {
    final result = await _send(
      () => http.get(
        Uri.parse('${ApiConstants.baseUrl}/locations'),
        headers: _headers,
      ),
    );
    return (result as List<dynamic>)
        .map((e) => Location.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Location> updateLocation({
    required String id,
    required String name,
    required String address,
    required bool isActive,
  }) async {
    final result = await _send(
      () => http.put(
        Uri.parse('${ApiConstants.baseUrl}/locations/$id'),
        headers: _headers,
        body: json.encode({
          'name': name,
          'address': address,
          'isActive': isActive,
        }),
      ),
    );
    final data = result as Map<String, dynamic>;
    return Location.fromJson(data['location'] ?? data);
  }
}
