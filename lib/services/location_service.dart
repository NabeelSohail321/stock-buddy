import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:stock_buddy/core/constants.dart';
import 'package:stock_buddy/models/location_model.dart';

class LocationService {
  final String token;
  final String baseUrl = ApiConstants.baseUrl;

  LocationService({required this.token});

  Future<Map<String, String>> _getHeaders() async {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Create Location (Admin Only)
  Future<Location> createLocation({
    required String name,
    String? address,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/locations'),
        headers: await _getHeaders(),
        body: json.encode({
          'name': name,
          'address': address,
        }),
      );

      if (response.statusCode == 201) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        return Location.fromJson(responseData['location']);
      } else {
        throw Exception('Failed to create location: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to create location: $e');
    }
  }

  // Get All Locations
  Future<List<Location>> getLocations() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/locations'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> responseData = json.decode(response.body);
        return responseData.map((locationData) => Location.fromJson(locationData)).toList();
      } else {
        throw Exception('Failed to load locations: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load locations: $e');
    }
  }

  // Update Location (Admin Only)
  Future<Location> updateLocation({
    required String id,
    required String name,
    required String address,
    required bool isActive,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/locations/$id'),
        headers: await _getHeaders(),
        body: json.encode({
          'name': name,
          'address': address,
          'isActive': isActive,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        return Location.fromJson(responseData['location']);
      } else {
        throw Exception('Failed to update location: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to update location: $e');
    }
  }
}