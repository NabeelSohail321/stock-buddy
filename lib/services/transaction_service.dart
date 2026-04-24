import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/transaction_model.dart';

class TransactionService {
  final String baseUrl;
  final String token;

  TransactionService({required this.baseUrl, required this.token});

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
    try {
      final Map<String, String> queryParameters = {
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

      final Uri uri = Uri.parse('$baseUrl/transactions').replace(
        queryParameters: queryParameters,
      );

      print('Fetching transactions from: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        List<dynamic> transactionsData = data['transactions'] ?? [];
        final List<Transaction> transactions = transactionsData
            .map((item) => Transaction.fromJson(item))
            .toList();

        final pagination = data['pagination'] ?? {};

        return {
          'transactions': transactions,
          'totalPages': pagination['pages'] ?? 1,
          'currentPage': pagination['page'] ?? page,
          'totalCount': pagination['total'] ?? transactions.length,
        };
      } else {
        throw Exception('Failed to load transactions: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error in getTransactions: $e');
      throw Exception('Failed to load transactions: $e');
    }
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
    try {
      final Map<String, String> queryParameters = {
        if (category != null) 'category': category,
        if (type != null) 'type': type,
        if (status != null) 'status': status,
        if (datePreset != null) 'datePreset': datePreset,
        if (anchorDate != null) 'anchorDate': anchorDate,
        if (startDate != null) 'startDate': startDate,
        if (endDate != null) 'endDate': endDate,
        if (search != null) 'search': search,
      };

      final Uri uri = Uri.parse('$baseUrl/transactions/export/print').replace(
        queryParameters: queryParameters,
      );

      print('Fetching transaction export HTML from: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return response.body;
      } else {
        throw Exception('Failed to export transactions: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in getTransactionExportHtml: $e');
      throw Exception('Failed to export transactions: $e');
    }
  }

  Future<bool> updateRepairChecklist(String transactionId, List<Map<String, dynamic>> items) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/transactions/$transactionId/repair-checklist'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'items': items}),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error in updateRepairChecklist: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> getRecentTransactions({int limit = 10}) async {
    return getTransactions(
      status: 'approved',
      page: 1,
      limit: limit,
    );
  }
}