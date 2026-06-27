import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../core/app_exception.dart';
import '../core/constants.dart';

class RepairService {
  final String token;

  RepairService({required this.token});

  Map<String, String> get _headers => {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

  Future<dynamic> _send(Future<http.Response> Function() fn,
      {Duration timeout = const Duration(seconds: 30)}) async {
    try {
      final response = await fn().timeout(timeout);
      debugPrint('[RepairService] ${response.statusCode}');
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return response.body.isNotEmpty ? json.decode(response.body) : null;
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
      debugPrint('[RepairService] unexpected: $e');
      throw AppException('An unexpected error occurred. Please try again.');
    }
  }

  Map<String, dynamic> _parseBody(String body) {
    try {
      return json.decode(body) as Map<String, dynamic>;
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

  Future<Map<String, dynamic>> sendToRepair({
    required String itemId,
    required String locationId,
    required int quantity,
    required String vendorName,
    String? serialNumber,
    String? note,
    String? photo,
  }) async {
    final result = await _send(
      () => http.post(
        Uri.parse('${ApiConstants.baseUrl}/repairs/send'),
        headers: _headers,
        body: json.encode({
          'itemId': itemId,
          'locationId': locationId,
          'quantity': quantity,
          'vendorName': vendorName,
          if (serialNumber != null && serialNumber.isNotEmpty) 'serialNumber': serialNumber,
          if (note != null && note.isNotEmpty) 'note': note,
          if (photo != null && photo.isNotEmpty) 'photo': photo,
        }),
      ),
      timeout: const Duration(seconds: 15),
    );
    return result as Map<String, dynamic>;
  }

  Future<List<dynamic>> getRepairTickets() async {
    final result = await _send(
      () => http.get(
        Uri.parse('${ApiConstants.baseUrl}/repairs'),
        headers: _headers,
      ),
      timeout: ApiConstants.connectTimeout,
    );
    return result as List<dynamic>;
  }

  Future<Map<String, dynamic>> disposeFromRepair({
    required String repairTicketId,
    String? reason,
    String? note,
  }) async {
    final result = await _send(
      () => http.post(
        Uri.parse('${ApiConstants.baseUrl}/repairs/dispose'),
        headers: _headers,
        body: json.encode({
          'repairTicketId': repairTicketId,
          if (reason != null) 'reason': reason,
          if (note != null) 'note': note,
        }),
      ),
      timeout: const Duration(seconds: 15),
    );
    return result as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> returnFromRepair({
    required String repairTicketId,
    required String locationId,
    String? note,
    List<Map<String, dynamic>>? checklist,
  }) async {
    final result = await _send(
      () => http.post(
        Uri.parse('${ApiConstants.baseUrl}/repairs/return'),
        headers: _headers,
        body: json.encode({
          'repairTicketId': repairTicketId,
          'locationId': locationId,
          if (note != null) 'note': note,
          if (checklist != null) 'checklist': checklist,
        }),
      ),
      timeout: const Duration(seconds: 15),
    );
    return result as Map<String, dynamic>;
  }
}

class ImageUtils {
  static final ImagePicker _picker = ImagePicker();

  static Future<String?> pickImageMobile(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );
      if (image != null) {
        final File imageFile = File(image.path);
        final List<int> imageBytes = await imageFile.readAsBytes();
        return base64Encode(imageBytes);
      }
      return null;
    } catch (e) {
      throw AppException('Failed to pick image: $e');
    }
  }

  static Future<String?> pickImageDesktop() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );
      if (result != null && result.files.single.path != null) {
        final File imageFile = File(result.files.single.path!);
        final List<int> imageBytes = await imageFile.readAsBytes();
        return base64Encode(imageBytes);
      }
      return null;
    } catch (e) {
      throw AppException('Failed to pick image: $e');
    }
  }

  static bool get isMobile => Platform.isAndroid || Platform.isIOS;
  static bool get isDesktop =>
      Platform.isWindows || Platform.isMacOS || Platform.isLinux;
}
