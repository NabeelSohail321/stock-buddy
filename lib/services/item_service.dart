import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../core/app_exception.dart';
import '../core/constants.dart';
import '../models/dashboard_model.dart';
import '../models/item_model.dart';
import '../models/location_model.dart';
import '../models/stock_model.dart';

class ItemsService {
  final http.Client client;
  final Future<String?> Function() getToken;

  ItemsService({required this.client, required this.getToken});

  Future<String> _requireToken() async {
    final token = await getToken();
    if (token == null || token.isEmpty) throw const AuthException('Session expired. Please log in again.');
    return token;
  }

  Future<dynamic> _send(Future<http.Response> Function(String token) fn) async {
    final token = await _requireToken();
    try {
      final response = await fn(token).timeout(ApiConstants.connectTimeout);
      debugPrint('[ItemsService] ${response.statusCode}');
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return response.body.isNotEmpty ? jsonDecode(response.body) : null;
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
      debugPrint('[ItemsService] unexpected: $e');
      throw AppException('An unexpected error occurred. Please try again.');
    }
  }

  Map<String, dynamic> _parseBody(String body) {
    try {
      return jsonDecode(body) as Map<String, dynamic>;
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

  Future<Item> createItem({
    required String name,
    required String sku,
    required String barcode,
    required String unit,
    required int threshold,
    String? locationId,
    String? managerId,
    int initialQuantity = 0,
    String? image,
    String? modelNumber,
    String? serialNumber,
    String? purchaseDate,
  }) async {
    final result = await _send((token) => client.post(
          Uri.parse('${ApiConstants.baseUrl}/items'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'name': name,
            'sku': sku,
            'barcode': barcode,
            'unit': unit,
            'threshold': threshold,
            if (locationId != null && locationId.isNotEmpty) 'locationId': locationId,
            if (managerId != null && managerId.isNotEmpty) 'managerId': managerId,
            'initialQuantity': initialQuantity,
            if (image != null && image.isNotEmpty) 'image': image,
            if (modelNumber != null && modelNumber.isNotEmpty) 'modelNumber': modelNumber,
            if (serialNumber != null && serialNumber.isNotEmpty) 'serialNumber': serialNumber,
            if (purchaseDate != null && purchaseDate.isNotEmpty) 'purchaseDate': purchaseDate,
          }),
        ));
    return Item.fromJson(result as Map<String, dynamic>);
  }

  Future<List<Item>> getItems() async {
    final result = await _send((token) => client.get(
          Uri.parse('${ApiConstants.baseUrl}/items'),
          headers: {'Authorization': 'Bearer $token'},
        ));
    return (result as List<dynamic>).map((e) => Item.fromJson(e)).toList();
  }

  Future<StockResponse> addStock(StockAddRequest request) async {
    final result = await _send((token) => client.post(
          Uri.parse('${ApiConstants.baseUrl}/stock/add'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode(request.toJson()),
        ));
    return StockResponse.fromJson(result as Map<String, dynamic>);
  }

  Future<List<Location>> getLocations() async {
    final result = await _send((token) => client.get(
          Uri.parse('${ApiConstants.baseUrl}/locations'),
          headers: {'Authorization': 'Bearer $token'},
        ));
    return (result as List<dynamic>).map((e) => Location.fromJson(e)).toList();
  }

  Future<List<Item>> searchItems(String query) async {
    final result = await _send((token) => client.get(
          Uri.parse('${ApiConstants.baseUrl}/items/search?query=${Uri.encodeQueryComponent(query)}'),
          headers: {'Authorization': 'Bearer $token'},
        ));
    return (result as List<dynamic>).map((e) => Item.fromJson(e)).toList();
  }

  Future<Item> getItemByBarcode(String barcode) async {
    final result = await _send((token) => client.get(
          Uri.parse('${ApiConstants.baseUrl}/items/barcode/$barcode'),
          headers: {'Authorization': 'Bearer $token'},
        ));
    return Item.fromJson(result as Map<String, dynamic>);
  }

  Future<Item> assignBarcode({
    required String itemId,
    String? barcode,
    bool overwrite = false,
  }) async {
    final result = await _send((token) => client.post(
          Uri.parse('${ApiConstants.baseUrl}/items/$itemId/barcode'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            if (barcode != null) 'barcode': barcode,
            'overwrite': overwrite,
          }),
        ));
    return Item.fromJson(result as Map<String, dynamic>);
  }

  Future<Item> getItemById(String id) async {
    final result = await _send((token) => client.get(
          Uri.parse('${ApiConstants.baseUrl}/items/$id'),
          headers: {'Authorization': 'Bearer $token'},
        ));
    return Item.fromJson(result as Map<String, dynamic>);
  }

  Future<Item> updateItem({
    required String id,
    required String name,
    required String unit,
    required int threshold,
    required String status,
    String? modelNumber,
    String? serialNumber,
    String? purchaseDate,
  }) async {
    final result = await _send((token) => client.put(
          Uri.parse('${ApiConstants.baseUrl}/items/$id'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'name': name,
            'unit': unit,
            'threshold': threshold,
            'status': status,
            if (modelNumber != null) 'modelNumber': modelNumber,
            if (serialNumber != null) 'serialNumber': serialNumber,
            if (purchaseDate != null && purchaseDate.isNotEmpty) 'purchaseDate': purchaseDate,
          }),
        ));
    return Item.fromJson(result as Map<String, dynamic>);
  }

  Future<void> deleteItem(String id) async {
    await _send((token) => client.delete(
          Uri.parse('${ApiConstants.baseUrl}/items/$id'),
          headers: {'Authorization': 'Bearer $token'},
        ));
  }

  Future<DashboardData> getDashboardData() async {
    final result = await _send((token) => client.get(
          Uri.parse('${ApiConstants.baseUrl}/dashboard'),
          headers: {'Authorization': 'Bearer $token'},
        ));
    return DashboardData.fromJson(result as Map<String, dynamic>);
  }

  String? convertImageToBase64(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) return null;
    try {
      final imageFile = File(imagePath);
      if (imageFile.existsSync()) {
        return base64Encode(imageFile.readAsBytesSync());
      }
    } catch (e) {
      debugPrint('[ItemsService] image conversion error: $e');
    }
    return null;
  }
}
