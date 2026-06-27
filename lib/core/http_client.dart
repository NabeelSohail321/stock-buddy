import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'app_exception.dart';
import 'constants.dart';

/// Centralised HTTP helper — wraps every request with timeout, network error
/// detection, and status-code → AppException mapping.
/// Services call [HttpClient.get] / [HttpClient.post] / etc. instead of
/// raw `http.*` methods.
class HttpClient {
  final http.Client _client;

  HttpClient(this._client);

  // ── request helpers ──────────────────────────────────────────────────────

  Future<dynamic> get(
    String path, {
    String? token,
    Map<String, String>? queryParams,
    Duration timeout = const Duration(seconds: 30),
  }) =>
      _execute(
        () => _client.get(
          _uri(path, queryParams),
          headers: _headers(token),
        ),
        timeout,
      );

  Future<dynamic> post(
    String path, {
    String? token,
    Map<String, dynamic>? body,
    Duration timeout = const Duration(seconds: 30),
  }) =>
      _execute(
        () => _client.post(
          _uri(path),
          headers: _headers(token, contentType: true),
          body: body != null ? jsonEncode(body) : null,
        ),
        timeout,
      );

  Future<dynamic> put(
    String path, {
    String? token,
    Map<String, dynamic>? body,
    Duration timeout = const Duration(seconds: 30),
  }) =>
      _execute(
        () => _client.put(
          _uri(path),
          headers: _headers(token, contentType: true),
          body: body != null ? jsonEncode(body) : null,
        ),
        timeout,
      );

  Future<dynamic> patch(
    String path, {
    String? token,
    Map<String, dynamic>? body,
    Duration timeout = const Duration(seconds: 30),
  }) =>
      _execute(
        () => _client.patch(
          _uri(path),
          headers: _headers(token, contentType: true),
          body: body != null ? jsonEncode(body) : null,
        ),
        timeout,
      );

  Future<dynamic> delete(
    String path, {
    String? token,
    Duration timeout = const Duration(seconds: 30),
  }) =>
      _execute(
        () => _client.delete(
          _uri(path),
          headers: _headers(token),
        ),
        timeout,
      );

  // ── internals ─────────────────────────────────────────────────────────────

  Uri _uri(String path, [Map<String, String>? queryParams]) {
    final base = path.startsWith('http')
        ? Uri.parse(path)
        : Uri.parse('${ApiConstants.baseUrl}$path');
    return queryParams != null && queryParams.isNotEmpty
        ? base.replace(queryParameters: queryParams)
        : base;
  }

  Map<String, String> _headers(String? token, {bool contentType = false}) {
    return {
      if (contentType) 'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Future<dynamic> _execute(
    Future<http.Response> Function() fn,
    Duration timeout,
  ) async {
    try {
      final response = await fn().timeout(timeout);
      return _handleResponse(response);
    } on SocketException {
      throw const NetworkException();
    } on TimeoutException {
      throw const RequestTimeoutException();
    } on AppException {
      rethrow;
    } catch (e) {
      debugPrint('[HttpClient] unexpected error: $e');
      throw AppException('An unexpected error occurred. Please try again.');
    }
  }

  dynamic _handleResponse(http.Response response) {
    debugPrint('[HTTP] ${response.request?.method} ${response.request?.url} → ${response.statusCode}');

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      try {
        return jsonDecode(response.body);
      } catch (_) {
        return response.body;
      }
    }

    final message = _extractMessage(response);

    switch (response.statusCode) {
      case 400:
        throw ValidationException(message);
      case 401:
        throw AuthException(message);
      case 403:
        throw ForbiddenException(message);
      case 404:
        throw NotFoundException(message);
      case 422:
        throw ValidationException(message);
      default:
        throw ServerException(message, response.statusCode);
    }
  }

  String _extractMessage(http.Response response) {
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return body['message']?.toString() ??
          body['error']?.toString() ??
          'Server error (${response.statusCode})';
    } catch (_) {
      return 'Server error (${response.statusCode})';
    }
  }
}
