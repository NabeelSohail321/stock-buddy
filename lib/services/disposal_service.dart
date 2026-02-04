import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants.dart';

class DisposalService {
  final String token;

  DisposalService({required this.token});

  // Existing requestDisposal method...
  Future<Map<String, dynamic>> requestDisposal({
    required String itemId,
    required String locationId,
    required int quantity,
    required String reason,
    String? note,
    required String photo,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/disposals/request'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'itemId': itemId,
        'locationId': locationId,
        'quantity': quantity,
        'reason': reason,
        'note': note,
        'photo': photo,
      }),
    );

    if (response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to submit disposal request: ${response.statusCode}');
    }
  }

  // New method to get pending disposal requests
  Future<List<dynamic>> getPendingDisposals() async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/disposals/pending'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to fetch pending disposals: ${response.statusCode}');
    }
  }

  // New method to approve/reject disposal
  Future<Map<String, dynamic>> approveDisposal({
    required String transactionId,
    required bool approved,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/disposals/approve'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'transactionId': transactionId,
        'approved': approved,
      }),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to approve disposal: ${response.statusCode}');
    }
  }
}