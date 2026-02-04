import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';

class ImageService {
  final ImagePicker _picker = ImagePicker();

  Future<String?> pickAndConvertImage() async {
    try {
      // Show option dialog
      final source = await _showImageSourceDialog();
      if (source == null) return null;

      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );

      if (image != null) {
        final bytes = await File(image.path).readAsBytes();
        return base64Encode(bytes);
      }
    } catch (e) {
      print('Image pick error: $e');
      rethrow;
    }
    return null;
  }

  Future<ImageSource?> _showImageSourceDialog() async {
    return await showDialog<ImageSource>(
      context: navigatorKey.currentContext!,
      builder: (context) => AlertDialog(
        title: const Text('Select Image Source'),
        content: const Text('Choose how you want to select an image'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, ImageSource.camera),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.camera_alt),
                SizedBox(width: 8),
                Text('Camera'),
              ],
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, ImageSource.gallery),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.photo_library),
                SizedBox(width: 8),
                Text('Gallery'),
              ],
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  // Helper method to get image widget from base64
  Widget imageFromBase64(String base64String, {double? width, double? height, BoxFit? fit}) {
    try {
      return Image.memory(
        base64Decode(base64String),
        width: width,
        height: height,
        fit: fit ?? BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: width,
            height: height,
            color: Colors.grey[200],
            child: const Icon(Icons.error_outline, color: Colors.grey),
          );
        },
      );
    } catch (e) {
      return Container(
        width: width,
        height: height,
        color: Colors.grey[200],
        child: const Icon(Icons.error_outline, color: Colors.grey),
      );
    }
  }



}

// Global navigator key for image service
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();