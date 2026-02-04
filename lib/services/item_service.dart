import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

import '../core/constants.dart';
import '../models/dashboard_model.dart';
import '../models/item_model.dart';
import '../models/location_model.dart';
import '../models/stock_model.dart';


class ItemsService {
  final http.Client client;
  final Future<String?> Function() getToken;

  ItemsService({
    required this.client,
    required this.getToken,
  });

  // Update the createItem method in ItemsService
  Future<Item> createItem({
    required String name,
    required String sku,
    required String barcode,
    required String unit,
    required int threshold,
    String? image, // Add optional image parameter
  }) async {
    final token = await getToken();
    if (token == null) {
      throw Exception('No authentication token found');
    }

    try {
      final Map<String, dynamic> requestBody = {
        'name': name,
        'sku': sku,
        'barcode': barcode,
        'unit': unit,
        'threshold': threshold,
      };

      // Add image to request if provided
      if (image != null && image.isNotEmpty) {
        requestBody['image'] = image;
      }

      final response = await client.post(
        Uri.parse('${ApiConstants.baseUrl}/items'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      ).timeout(ApiConstants.connectTimeout);

      print('Create Item Response Status: ${response.statusCode}');
      print('Create Item Response Body: ${response.body}');

      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        return Item.fromJson(responseData);
      } else {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        final errorMessage = errorData['message'] ?? 'Failed to create item';
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('Create Item Error: $e');
      rethrow;
    }
  }

// Add this helper method for image conversion
  String? convertImageToBase64(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) return null;

    try {
      final imageFile = File(imagePath);
      if (imageFile.existsSync()) {
        final bytes = imageFile.readAsBytesSync();
        final base64Image = base64Encode(bytes);

        // Determine MIME type from file extension
        String mimeType = 'image/jpeg'; // default
        if (imagePath.toLowerCase().endsWith('.png')) {
          mimeType = 'image/png';
        } else if (imagePath.toLowerCase().endsWith('.gif')) {
          mimeType = 'image/gif';
        } else if (imagePath.toLowerCase().endsWith('.webp')) {
          mimeType = 'image/webp';
        }

        return '$base64Image';
      }
    } catch (e) {
      print('Error converting image to base64: $e');
    }
    return null;
  }

  Future<List<Item>> getItems() async {
    final token = await getToken();
    if (token == null) {
      throw Exception('No authentication token found');
    }

    try {
      final response = await client.get(
        Uri.parse('${ApiConstants.baseUrl}/items'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      ).timeout(ApiConstants.connectTimeout);

      print('Get Items Response Status: ${response.statusCode}');
      print('Get Items Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as List;
        return responseData.map((item) => Item.fromJson(item)).toList();
      } else {
        throw Exception('Failed to fetch items: ${response.statusCode}');
      }
    } catch (e) {
      print('Get Items Error: $e');
      rethrow;
    }
  }

  Future<StockResponse> addStock(StockAddRequest request) async {
    final token = await getToken();
    if (token == null) {
      throw Exception('No authentication token found');
    }

    try {
      final response = await client.post(
        Uri.parse('${ApiConstants.baseUrl}/stock/add'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(request.toJson()),
      ).timeout(ApiConstants.connectTimeout);

      print('Add Stock Response Status: ${response.statusCode}');
      print('Add Stock Response Body: ${response.body}');

      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        return StockResponse.fromJson(responseData);
      } else {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        final errorMessage = errorData['message'] ?? 'Failed to add stock';
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('Add Stock Error: $e');
      rethrow;
    }


  }

  Future<List<Location>> getLocations() async {
    final token = await getToken();
    if (token == null) {
      throw Exception('No authentication token found');
    }

    try {
      final response = await client.get(
        Uri.parse('${ApiConstants.baseUrl}/locations'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      ).timeout(ApiConstants.connectTimeout);

      print('Get Locations Response Status: ${response.statusCode}');
      print('Get Locations Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as List;
        return responseData.map((location) => Location.fromJson(location)).toList();
      } else {
        throw Exception('Failed to fetch locations: ${response.statusCode}');
      }
    } catch (e) {
      print('Get Locations Error: $e');
      rethrow;
    }
  }


  // Add these methods to your existing ItemsService class

// Search Items
  Future<List<Item>> searchItems(String query) async {
    final token = await getToken();
    if (token == null) {
      throw Exception('No authentication token found');
    }

    try {
      final response = await client.get(
        Uri.parse('${ApiConstants.baseUrl}/items/search?query=$query'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      ).timeout(ApiConstants.connectTimeout);

      print('Search Items Response Status: ${response.statusCode}');
      print('Search Items Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as List;
        return responseData.map((item) => Item.fromJson(item)).toList();
      } else {
        throw Exception('Failed to search items: ${response.statusCode}');
      }
    } catch (e) {
      print('Search Items Error: $e');
      rethrow;
    }
  }

// Lookup Item by Barcode
  Future<Item> getItemByBarcode(String barcode) async {
    final token = await getToken();
    if (token == null) {
      throw Exception('No authentication token found');
    }

    try {
      final response = await client.get(
        Uri.parse('${ApiConstants.baseUrl}/items/barcode/$barcode'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      ).timeout(ApiConstants.connectTimeout);

      print('Get Item by Barcode Response Status: ${response.statusCode}');
      print('Get Item by Barcode Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        return Item.fromJson(responseData);
      } else {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        final errorMessage = errorData['message'] ?? 'Item not found';
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('Get Item by Barcode Error: $e');
      rethrow;
    }
  }

// Assign or Generate Barcode (Admin Only)
  Future<Item> assignBarcode({
    required String itemId,
    String? barcode,
    bool overwrite = false,
  }) async {
    final token = await getToken();
    if (token == null) {
      throw Exception('No authentication token found');
    }

    try {
      final response = await client.post(
        Uri.parse('${ApiConstants.baseUrl}/items/$itemId/barcode'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          if (barcode != null) 'barcode': barcode,
          'overwrite': overwrite,
        }),
      ).timeout(ApiConstants.connectTimeout);

      print('Assign Barcode Response Status: ${response.statusCode}');
      print('Assign Barcode Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        return Item.fromJson(responseData);
      } else {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        final errorMessage = errorData['message'] ?? 'Failed to assign barcode';
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('Assign Barcode Error: $e');
      rethrow;
    }
  }

// Get Item by ID
  Future<Item> getItemById(String id) async {
    final token = await getToken();
    if (token == null) {
      throw Exception('No authentication token found');
    }

    try {
      final response = await client.get(
        Uri.parse('${ApiConstants.baseUrl}/items/$id'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      ).timeout(ApiConstants.connectTimeout);

      print('Get Item by ID Response Status: ${response.statusCode}');
      print('Get Item by ID Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        return Item.fromJson(responseData);
      } else {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        final errorMessage = errorData['message'] ?? 'Item not found';
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('Get Item by ID Error: $e');
      rethrow;
    }
  }

// Update Item (Admin Only)
  Future<Item> updateItem({
    required String id,
    required String name,
    required String unit,
    required int threshold,
    required String status,
  }) async {
    final token = await getToken();
    if (token == null) {
      throw Exception('No authentication token found');
    }

    try {
      final response = await client.put(
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
        }),
      ).timeout(ApiConstants.connectTimeout);

      print('Update Item Response Status: ${response.statusCode}');
      print('Update Item Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        return Item.fromJson(responseData);
      } else {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        final errorMessage = errorData['message'] ?? 'Failed to update item';
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('Update Item Error: $e');
      rethrow;
    }
  }

  // Add this method to your existing ItemsService class

// Get Dashboard Data
  Future<DashboardData> getDashboardData() async {
    final token = await getToken();
    if (token == null) {
      throw Exception('No authentication token found');
    }

    try {
      final response = await client.get(
        Uri.parse('${ApiConstants.baseUrl}/dashboard'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      ).timeout(ApiConstants.connectTimeout);

      print('Dashboard Response Status: ${response.statusCode}');
      print('Dashboard Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        return DashboardData.fromJson(responseData);
      } else {
        throw Exception('Failed to fetch dashboard data: ${response.statusCode}');
      }
    } catch (e) {
      print('Dashboard Error: $e');
      rethrow;
    }
  }


// You can add more methods here for getting items, updating, etc.
}