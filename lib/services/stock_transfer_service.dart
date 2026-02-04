import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/stock_transfer_model.dart';

class StockTransferService {
  final String baseUrl;
  final String token;

  StockTransferService({required this.baseUrl, required this.token});

  Future<StockTransferResponse> transferStock(StockTransferRequest request) async {
    try {
      final Uri uri = Uri.parse('$baseUrl/stock/transfer');

      print('Transferring stock: ${request.toJson()}');

      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(request.toJson()),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> data = json.decode(response.body);
        return StockTransferResponse.fromJson(data);
      } else {
        throw Exception('Failed to transfer stock: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error in transferStock: $e');
      throw Exception('Failed to transfer stock: $e');
    }
  }
}