import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../core/constants.dart';

class RepairService {
  final String token;

  RepairService({required this.token});

  Future<Map<String, dynamic>> sendToRepair({
    required String itemId,
    required String locationId,
    required int quantity,
    required String vendorName,
    String? serialNumber,
    String? note,
    String? photo, // base64 encoded image
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/repairs/send'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'itemId': itemId,
        'locationId': locationId,
        'quantity': quantity,
        'vendorName': vendorName,
        'serialNumber': serialNumber,
        'note': note,
        'photo': photo,
      }),
    );

    if (response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to send item for repair: ${response.statusCode}');
    }
  }

  Future<List<dynamic>> getRepairTickets() async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/repairs'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to fetch repair tickets: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> returnFromRepair({
    required String repairTicketId,
    required String locationId,
    String? note,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/repairs/return'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'repairTicketId': repairTicketId,
        'locationId': locationId,
        'note': note,
      }),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to return from repair: ${response.statusCode}');
    }
  }
}

// Image utility class
class ImageUtils {
  static final ImagePicker _picker = ImagePicker();

  // For mobile devices - pick from camera or gallery
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
      throw Exception('Failed to pick image: $e');
    }
  }

  // For desktop devices - pick from file system
  static Future<String?> pickImageDesktop() async {
    try {
      // For desktop, we'll use file_picker package
      // First, add file_picker to your pubspec.yaml
      // file_picker: ^5.6.1
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
      throw Exception('Failed to pick image: $e');
    }
  }

  // Check if device is mobile
  static bool get isMobile {
    return Platform.isAndroid || Platform.isIOS;
  }

  // Check if device is desktop
  static bool get isDesktop {
    return Platform.isWindows || Platform.isMacOS || Platform.isLinux;
  }
}