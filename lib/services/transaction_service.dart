import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/transaction_model.dart';

class TransactionService {
  final String baseUrl;
  final String token;

  TransactionService({required this.baseUrl, required this.token});

  Future<Map<String, dynamic>> getTransactions({
    String? type,
    String? status,
    String? startDate,
    String? endDate,
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final Uri uri = Uri.parse('$baseUrl/transactions').replace(
        queryParameters: {
          if (type != null) 'type': type,
          if (status != null) 'status': status,
          if (startDate != null) 'startDate': startDate,
          if (endDate != null) 'endDate': endDate,
          'page': page.toString(),
          'limit': limit.toString(),
        },
      );

      print('Fetching transactions from: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      // print('Response status: ${response.statusCode}');
      // print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        // Extract transactions array
        List<dynamic> transactionsData = data['transactions'] ?? [];

        final List<Transaction> transactions = transactionsData
            .map((item) => Transaction.fromJson(item))
            .toList();

        // Extract pagination info
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

  Future<Map<String, dynamic>> getRecentTransactions({int limit = 10}) async {
    return getTransactions(
      status: 'approved',
      page: 1,
      limit: limit,
    );
  }
}