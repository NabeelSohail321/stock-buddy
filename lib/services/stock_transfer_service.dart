import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../core/app_exception.dart';
import '../models/stock_transfer_model.dart';

class StockTransferService {
  final String baseUrl;
  final String token;

  StockTransferService({required this.baseUrl, required this.token});

  Map<String, String> get _headers => {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

  Future<StockTransferResponse> transferStock(StockTransferRequest request) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/stock/transfer'),
            headers: _headers,
            body: json.encode(request.toJson()),
          )
          .timeout(const Duration(seconds: 30));

      debugPrint('[StockTransferService] ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return StockTransferResponse.fromJson(json.decode(response.body));
      }

      final body = _parseBody(response.body);
      final message = body['message'] ?? body['error'] ?? 'Error ${response.statusCode}';
      switch (response.statusCode) {
        case 401:
          throw AuthException(message);
        case 403:
          throw ForbiddenException(message);
        case 422:
          throw ValidationException(message);
        default:
          throw ServerException(message, response.statusCode);
      }
    } on SocketException {
      throw const NetworkException();
    } on TimeoutException {
      throw const RequestTimeoutException();
    } on AppException {
      rethrow;
    } catch (e) {
      debugPrint('[StockTransferService] unexpected: $e');
      throw AppException('Failed to transfer stock. Please try again.');
    }
  }

  Map<String, dynamic> _parseBody(String body) {
    try {
      return json.decode(body) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }
}
