import 'dart:convert';
import 'package:http/http.dart' as http;

import '../core/constants.dart';

class TransferService {
  final String token;

  TransferService({required this.token});

  Future<List<dynamic>> getPendingTransfers() async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/stock/transfers/pending'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      print("Helooo                          ");
      print(json.decode(response.body));
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load pending transfers: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> reviewTransfer({
    required String transactionId,
    required bool approved,
    String note = '',
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/stock/transfer/review'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'transactionId': transactionId,
        'approved': approved,
        'note': note,
      }),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to review transfer: ${response.statusCode}');
    }
  }
}