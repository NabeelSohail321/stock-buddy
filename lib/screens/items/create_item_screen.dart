import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';

import '../../providers/items_provider.dart';
import 'barcode_scanner_screen.dart';

class CreateItemScreen extends StatefulWidget {
  const CreateItemScreen({super.key});

  @override
  State<CreateItemScreen> createState() => _CreateItemScreenState();
}

class _CreateItemScreenState extends State<CreateItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _skuController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _thresholdController = TextEditingController(text: '0');

  String _selectedUnit = 'pcs';
  final List<String> _selectedLocations = [];
  bool _autoGenerateBarcode = false;
  File? _selectedImage;
  String? _base64Image;

  // Available units and locations
  final List<String> _units = [
    'pcs',
    'kg',
    'g',
    'lb',
    'oz',
    'L',
    'mL',
    'm',
    'cm',
    'mm',
    'box',
    'pack',
    'bottle',
    'can',
  ];

  final List<String> _availableLocations = [
    'Warehouse',
    'Store A',
    'Store B',
    'Store C',
    'Storage Room',
    'Main Floor',
    'Backroom',
  ];

  final ImagePicker _imagePicker = ImagePicker();

  @override
  void dispose() {
    _nameController.dispose();
    _skuController.dispose();
    _barcodeController.dispose();
    _thresholdController.dispose();
    super.dispose();
  }

  Future<void> _createItem() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedLocations.isEmpty) {
        // ScaffoldMessenger.of(context).showSnackBar(
        //   const SnackBar(
        //     content: Text('Please select at least one location'),
        //     backgroundColor: Colors.red,
        //   ),
        // );
        // return;
      }

      final itemsProvider = context.read<ItemsProvider>();

      // Generate barcode if auto-generate is enabled and no barcode is entered
      String barcode = _barcodeController.text.trim();
      if (_autoGenerateBarcode && barcode.isEmpty) {
        barcode = itemsProvider.generateBarcode();
      }

      final success = await itemsProvider.createItem(
        name: _nameController.text.trim(),
        sku: _skuController.text.trim(),
        barcode: barcode,
        unit: _selectedUnit,
        threshold: int.tryParse(_thresholdController.text) ?? 0,
        locations: _selectedLocations,
        image: _base64Image,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _autoGenerateBarcode && _barcodeController.text.isEmpty
                  ? 'Item created successfully with generated barcode!'
                  : 'Item created successfully!',
            ),
            backgroundColor: Colors.green,
          ),
        );

        // Clear form after successful creation
        _formKey.currentState!.reset();
        setState(() {
          _selectedUnit = 'pcs';
          _selectedLocations.clear();
          _thresholdController.text = '0';
          _autoGenerateBarcode = false;
          _barcodeController.clear();
          _selectedImage = null;
          _base64Image = null;
        });
      }
    }
  }

  void _toggleLocation(String location) {
    setState(() {
      if (_selectedLocations.contains(location)) {
        _selectedLocations.remove(location);
      } else {
        _selectedLocations.add(location);
      }
    });
  }

  void _generateBarcodeNow() {
    final itemsProvider = context.read<ItemsProvider>();
    final barcode = itemsProvider.generateBarcode();
    setState(() {
      _barcodeController.text = barcode;
      _autoGenerateBarcode = false; // User is manually setting barcode now
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Generated barcode: $barcode'),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _clearBarcode() {
    setState(() {
      _barcodeController.clear();
      _autoGenerateBarcode = false;
    });
  }

  // New method to handle barcode scanning
  Future<void> _scanBarcode() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const BarcodeScannerScreen(),
      ),
    );

    if (result != null && result is String) {
      setState(() {
        _barcodeController.text = result;
        _autoGenerateBarcode = false; // User scanned a barcode, so disable auto-generate
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Scanned barcode: $result'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  // Image handling methods
  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );

      if (image != null) {
        await _processImage(File(image.path));
      }
    } catch (e) {
      print('Error picking image from gallery: $e');
      _showErrorSnackBar('Failed to pick image from gallery');
    }
  }

  Future<void> _takePhotoWithCamera() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );

      if (image != null) {
        await _processImage(File(image.path));
      }
    } catch (e) {
      print('Error taking photo: $e');
      _showErrorSnackBar('Failed to take photo');
    }
  }

  Future<void> _processImage(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final base64String = base64Encode(bytes);

      // Determine MIME type from file extension
      String mimeType = 'image/jpeg'; // default
      final path = imageFile.path.toLowerCase();
      if (path.endsWith('.png')) {
        mimeType = 'image/png';
      } else if (path.endsWith('.gif')) {
        mimeType = 'image/gif';
      } else if (path.endsWith('.webp')) {
        mimeType = 'image/webp';
      }

      setState(() {
        _selectedImage = imageFile;
        _base64Image = '$base64String';
      });

      _showSuccessSnackBar('Image selected successfully');
    } catch (e) {
      print('Error processing image: $e');
      _showErrorSnackBar('Failed to process image');
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
      _base64Image = null;
    });
    _showSuccessSnackBar('Image removed');
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final itemsProvider = context.watch<ItemsProvider>();
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width >= 768;
    final isMobile = size.width < 768;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Create New Item'),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
        actions: [
          if (itemsProvider.isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 24 : 16,
          vertical: 16,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Error Message
              if (itemsProvider.errorMessage.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red.shade600, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          itemsProvider.errorMessage,
                          style: TextStyle(color: Colors.red.shade600),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: Colors.red.shade600, size: 20),
                        onPressed: () => itemsProvider.clearError(),
                      ),
                    ],
                  ),
                ),

              // Main Form Card
              Card(
                elevation: 2,
                shadowColor: Colors.black12,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Item Details',
                        style: TextStyle(
                          fontSize: isDesktop ? 20 : 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Image Selection Section
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Item Image (Optional)',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 12),

                          if (_selectedImage != null)
                            Column(
                              children: [
                                Container(
                                  width: 150,
                                  height: 150,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.grey.shade300),
                                    color: Colors.grey.shade50,
                                  ),
                                  child: Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.file(
                                          _selectedImage!,
                                          fit: BoxFit.cover,
                                          width: 150,
                                          height: 150,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Container(
                                              color: Colors.grey.shade200,
                                              child: const Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Icon(Icons.error, color: Colors.red, size: 40),
                                                  SizedBox(height: 8),
                                                  Text(
                                                    'Error loading image',
                                                    style: TextStyle(fontSize: 12, color: Colors.red),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                      Positioned(
                                        top: 4,
                                        right: 4,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.black54,
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: IconButton(
                                            icon: const Icon(Icons.close, size: 16, color: Colors.white),
                                            onPressed: _removeImage,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                              ],
                            )
                          else
                            Column(
                              children: [
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                                    borderRadius: BorderRadius.circular(12),
                                    color: Colors.grey.shade50,
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(Icons.photo_camera_back, size: 48, color: Colors.grey.shade400),
                                      const SizedBox(height: 8),
                                      Text(
                                        'No image selected',
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      if (isDesktop)
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            ElevatedButton.icon(
                                              onPressed: _pickImageFromGallery,
                                              icon: const Icon(Icons.photo_library),
                                              label: const Text('Choose from Gallery'),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.blue.shade50,
                                                foregroundColor: Colors.blue.shade700,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            ElevatedButton.icon(
                                              onPressed: _takePhotoWithCamera,
                                              icon: const Icon(Icons.camera_alt),
                                              label: const Text('Take Photo'),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.green.shade50,
                                                foregroundColor: Colors.green.shade700,
                                              ),
                                            ),
                                          ],
                                        )
                                      else
                                        Column(
                                          children: [
                                            SizedBox(
                                              width: double.infinity,
                                              child: ElevatedButton.icon(
                                                onPressed: _pickImageFromGallery,
                                                icon: const Icon(Icons.photo_library),
                                                label: const Text('Choose from Gallery'),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.blue.shade50,
                                                  foregroundColor: Colors.blue.shade700,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            SizedBox(
                                              width: double.infinity,
                                              child: ElevatedButton.icon(
                                                onPressed: _takePhotoWithCamera,
                                                icon: const Icon(Icons.camera_alt),
                                                label: const Text('Take Photo'),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.green.shade50,
                                                  foregroundColor: Colors.green.shade700,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                          const SizedBox(height: 8),
                          Text(
                            'Supported formats: JPEG, PNG, GIF, WebP. Recommended size: 800x800px',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Name Field
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Item Name *',
                          prefixIcon: const Icon(Icons.inventory_2_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          hintText: 'e.g., Laptop Dell XPS 13',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter item name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // SKU Field
                      TextFormField(
                        controller: _skuController,
                        decoration: InputDecoration(
                          labelText: 'SKU *',
                          prefixIcon: const Icon(Icons.tag_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          hintText: 'e.g., LP-DELL-XPS13-001',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter SKU';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Barcode Section
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Barcode Options Row
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Barcode Options',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ),
                              // Auto-generate toggle
                              Row(
                                children: [
                                  Text(
                                    'Auto-generate',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Switch(
                                    value: _autoGenerateBarcode,
                                    onChanged: (value) {
                                      setState(() {
                                        _autoGenerateBarcode = value;
                                        if (value) {
                                          _barcodeController.clear();
                                        }
                                      });
                                    },
                                    activeColor: Colors.blue.shade600,
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Barcode input field with actions
                          Stack(
                            children: [
                              TextFormField(
                                controller: _barcodeController,
                                decoration: InputDecoration(
                                  labelText: _autoGenerateBarcode
                                      ? 'Barcode (Will be auto-generated)'
                                      : 'Barcode',
                                  prefixIcon: const Icon(Icons.qr_code_outlined),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  hintText: 'e.g., 1234567890123',
                                  suffixIcon: _barcodeController.text.isNotEmpty
                                      ? IconButton(
                                    icon: const Icon(Icons.clear, size: 20),
                                    onPressed: _clearBarcode,
                                  )
                                      : null,
                                ),
                                enabled: !_autoGenerateBarcode,
                                readOnly: _autoGenerateBarcode,
                              ),
                              if (!_autoGenerateBarcode && _barcodeController.text.isEmpty)
                                Positioned(
                                  right: isMobile ? 10 : 120, // Adjust position for scan button
                                  top: 8,
                                  child: ElevatedButton.icon(
                                    onPressed: _generateBarcodeNow,
                                    icon: const Icon(Icons.autorenew, size: 16),
                                    label: const Text('Generate'),
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      backgroundColor: Colors.blue.shade50,
                                      foregroundColor: Colors.blue.shade700,
                                      textStyle: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ),
                            ],
                          ),

                          // Scan Button for Mobile
                          if (isMobile && !_autoGenerateBarcode) ...[
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: _scanBarcode,
                                icon: const Icon(Icons.camera_alt_rounded),
                                label: const Text('Scan Barcode from Camera'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  side: BorderSide(color: Colors.blue.shade400),
                                ),
                              ),
                            ),
                          ],

                          // Help text
                          const SizedBox(height: 8),
                          Text(
                            _autoGenerateBarcode
                                ? 'A unique barcode will be automatically generated when you create the item'
                                : isMobile
                                ? 'Enter a custom barcode, generate one, or scan using camera'
                                : 'Enter a custom barcode or generate one now',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Scan Button for Desktop/Tablet
                      if (!isMobile && !_autoGenerateBarcode)
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _scanBarcode,
                            icon: const Icon(Icons.camera_alt_rounded),
                            label: const Text('Scan Barcode from Camera'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              side: BorderSide(color: Colors.blue.shade400),
                            ),
                          ),
                        ),
                      if (!isMobile && !_autoGenerateBarcode)
                        const SizedBox(height: 16),

                      // Unit and Threshold Row
                      if (isDesktop)
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: _buildUnitDropdown(),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 1,
                              child: TextFormField(
                                controller: _thresholdController,
                                decoration: InputDecoration(
                                  labelText: 'Low Stock Threshold *',
                                  prefixIcon: const Icon(Icons.warning_amber_outlined),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter threshold';
                                  }
                                  final threshold = int.tryParse(value);
                                  if (threshold == null || threshold < 0) {
                                    return 'Please enter a valid number';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        )
                      else
                        Column(
                          children: [
                            _buildUnitDropdown(),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _thresholdController,
                              decoration: InputDecoration(
                                labelText: 'Low Stock Threshold *',
                                prefixIcon: const Icon(Icons.warning_amber_outlined),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter threshold';
                                }
                                final threshold = int.tryParse(value);
                                if (threshold == null || threshold < 0) {
                                  return 'Please enter a valid number';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Create Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: itemsProvider.isLoading ? null : _createItem,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade800,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: itemsProvider.isLoading
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                      : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        'Create Item',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                      if (_autoGenerateBarcode) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.qr_code, color: Colors.white, size: 16),
                      ],
                      if (_selectedImage != null) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.photo, color: Colors.white, size: 16),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUnitDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedUnit,
      decoration: InputDecoration(
        labelText: 'Unit *',
        prefixIcon: const Icon(Icons.scale_outlined),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      items: _units.map((String unit) {
        return DropdownMenuItem<String>(
          value: unit,
          child: Text(unit.toUpperCase()),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedUnit = value!;
        });
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select a unit';
        }
        return null;
      },
    );
  }
}