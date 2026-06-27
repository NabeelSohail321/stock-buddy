import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../core/app_exception.dart';
import '../core/constants.dart';

class TransferService {
  final String token;

  TransferService({required this.token});

  Map<String, String> get _headers => {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

  Future<dynamic> _send(Future<http.Response> Function() fn) async {
    try {
      final response = await fn().timeout(ApiConstants.connectTimeout);
      debugPrint('[TransferService] ${response.statusCode}');
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
      debugPrint('[TransferService] unexpected: $e');
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
      default:
        throw ServerException(message, code);
    }
  }

  Future<List<dynamic>> getPendingTransfers() async {
    final result = await _send(
      () => http.get(
        Uri.parse('${ApiConstants.baseUrl}/stock/transfers/pending'),
        headers: _headers,
      ),
    );
    return result as List<dynamic>;
  }

  Future<Map<String, dynamic>> reviewTransfer({
    required String transactionId,
    required bool approved,
    String note = '',
  }) async {
    final result = await _send(
      () => http.post(
        Uri.parse('${ApiConstants.baseUrl}/stock/transfer/review'),
        headers: _headers,
        body: json.encode({
          'transactionId': transactionId,
          'approved': approved,
          'note': note,
        }),
      ),
    );
    return result as Map<String, dynamic>;
  }
}
