import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants.dart';

class StockService {
  final String token;

  StockService({required this.token});

  // Get stock by location
  Future<List<dynamic>> getStockByLocation(String locationId) async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/stock/location/$locationId'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to fetch stock by location: ${response.statusCode}');
    }
  }
}