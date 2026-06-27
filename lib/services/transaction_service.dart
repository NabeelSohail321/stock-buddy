import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../core/app_exception.dart';
import '../models/transaction_model.dart';

class TransactionService {
  final String baseUrl;
  final String token;

  TransactionService({required this.baseUrl, required this.token});

  Map<String, String> get _headers => {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

  Future<dynamic> _send(Future<http.Response> Function() fn,
      {Duration timeout = const Duration(seconds: 30)}) async {
    try {
      final response = await fn().timeout(timeout);
      debugPrint('[TransactionService] ${response.statusCode}');
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
      debugPrint('[TransactionService] unexpected: $e');
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

  Future<Map<String, dynamic>> getTransactions({
    String? category,
    String? type,
    String? status,
    String? datePreset,
    String? anchorDate,
    String? startDate,
    String? endDate,
    String? search,
    int page = 1,
    int limit = 50,
  }) async {
    final queryParameters = <String, String>{
      if (category != null) 'category': category,
      if (type != null) 'type': type,
      if (status != null) 'status': status,
      if (datePreset != null) 'datePreset': datePreset,
      if (anchorDate != null) 'anchorDate': anchorDate,
      if (startDate != null) 'startDate': startDate,
      if (endDate != null) 'endDate': endDate,
      if (search != null) 'search': search,
      'page': page.toString(),
      'limit': limit.toString(),
    };

    final result = await _send(
      () => http.get(
        Uri.parse('$baseUrl/transactions')
            .replace(queryParameters: queryParameters),
        headers: _headers,
      ),
    );

    final data = result as Map<String, dynamic>;
    final transactionsData = data['transactions'] as List<dynamic>? ?? [];
    final pagination = data['pagination'] as Map<String, dynamic>? ?? {};

    return {
      'transactions':
          transactionsData.map((e) => Transaction.fromJson(e)).toList(),
      'totalPages': pagination['pages'] ?? 1,
      'currentPage': pagination['page'] ?? page,
      'totalCount': pagination['total'] ?? transactionsData.length,
    };
  }

  Future<String> getTransactionExportHtml({
    String? category,
    String? type,
    String? status,
    String? datePreset,
    String? anchorDate,
    String? startDate,
    String? endDate,
    String? search,
  }) async {
    final queryParameters = <String, String>{
      if (category != null) 'category': category,
      if (type != null) 'type': type,
      if (status != null) 'status': status,
      if (datePreset != null) 'datePreset': datePreset,
      if (anchorDate != null) 'anchorDate': anchorDate,
      if (startDate != null) 'startDate': startDate,
      if (endDate != null) 'endDate': endDate,
      if (search != null) 'search': search,
    };

    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/transactions/export/print')
                .replace(queryParameters: queryParameters),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) return response.body;
      throw ServerException('Failed to export transactions', response.statusCode);
    } on SocketException {
      throw const NetworkException();
    } on TimeoutException {
      throw const RequestTimeoutException();
    } on AppException {
      rethrow;
    }
  }

  Future<bool> updateRepairChecklist(
      String transactionId, List<Map<String, dynamic>> items) async {
    try {
      final response = await http
          .patch(
            Uri.parse('$baseUrl/transactions/$transactionId/repair-checklist'),
            headers: _headers,
            body: json.encode({'items': items}),
          )
          .timeout(const Duration(seconds: 30));
      return response.statusCode == 200;
    } on SocketException {
      throw const NetworkException();
    } on TimeoutException {
      throw const RequestTimeoutException();
    } catch (e) {
      debugPrint('[TransactionService] updateRepairChecklist error: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> getRecentTransactions({int limit = 10}) {
    return getTransactions(status: 'approved', page: 1, limit: limit);
  }
}
