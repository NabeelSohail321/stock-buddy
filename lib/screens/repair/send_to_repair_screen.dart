import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:stock_buddy/providers/items_provider.dart';
import 'package:stock_buddy/providers/repair_provider.dart';
import 'package:stock_buddy/models/item_model.dart';
import 'package:stock_buddy/models/location_model.dart';

import '../items/barcode_scanner_screen.dart';

class SendToRepairScreen extends StatefulWidget {
  const SendToRepairScreen({Key? key}) : super(key: key);

  @override
  State<SendToRepairScreen> createState() => _SendToRepairScreenState();
}

class _SendToRepairScreenState extends State<SendToRepairScreen> {
  final _formKey = GlobalKey<FormState>();
  final _vendorNameController = TextEditingController();
  final _serialNumberController = TextEditingController();
  final _noteController = TextEditingController();
  final _quantityController = TextEditingController();
  final _barcodeController = TextEditingController();

  String? _selectedItemId;
  String? _selectedLocationId;
  int _availableQuantity = 0;
  bool _isInitialLoading = true;
  String? _base64Image;
  Uint8List? _imageBytes;
  bool _isScanningBarcode = false;
  String? _barcodeSearchError;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshData();
    });
  }

  Future<void> _refreshData() async {
    setState(() {
      _isInitialLoading = true;
    });

    final itemsProvider = Provider.of<ItemsProvider>(context, listen: false);

    await Future.wait([
      itemsProvider.fetchItems(),
      itemsProvider.fetchLocations(),
    ]);

    setState(() {
      _isInitialLoading = false;
    });
  }

  void _resetForm() {
    setState(() {
      _selectedItemId = null;
      _selectedLocationId = null;
      _availableQuantity = 0;
      _base64Image = null;
      _imageBytes = null;
      _barcodeController.clear();
      _barcodeSearchError = null;
    });
    _vendorNameController.clear();
    _serialNumberController.clear();
    _noteController.clear();
    _quantityController.clear();
  }

  // Barcode scanning methods
  Future<void> _scanBarcode() async {
    setState(() {
      _isScanningBarcode = true;
    });

    try {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const BarcodeScannerScreen(),
        ),
      );

      if (result != null && result is String) {
        _barcodeController.text = result;
        await _searchItemByBarcode(result);
      }
    } catch (e) {
      _showError('Failed to scan barcode: $e');
    } finally {
      setState(() {
        _isScanningBarcode = false;
      });
    }
  }

  Future<void> _searchItemByBarcode(String barcode) async {
    if (barcode.isEmpty) return;

    setState(() {
      _barcodeSearchError = null;
    });

    final itemsProvider = Provider.of<ItemsProvider>(context, listen: false);

    try {
      final item = await itemsProvider.getItemByBarcode(barcode);

      if (item != null && mounted) {
        setState(() {
          _selectedItemId = item.id;
          _selectedLocationId = null;
          _availableQuantity = 0;
          _barcodeSearchError = null;
        });

        _updateAvailableQuantity();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Item found: ${item.name}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        setState(() {
          _barcodeSearchError = 'No item found with barcode: $barcode';
        });
      }
    } catch (e) {
      setState(() {
        _barcodeSearchError = 'Error searching item: ${e.toString().replaceAll('Exception: ', '')}';
      });
    }
  }

  void _clearBarcodeSearch() {
    setState(() {
      _barcodeController.clear();
      _barcodeSearchError = null;
      _selectedItemId = null;
      _selectedLocationId = null;
      _availableQuantity = 0;
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _pickImage() async {
    try {
      String? base64Image;
      Uint8List? imageBytes;

      if (Platform.isAndroid || Platform.isIOS) {
        // Mobile - show option for camera or gallery
        final source = await _showImageSourceDialog();
        if (source == null) return;

        final ImagePicker picker = ImagePicker();
        final XFile? image = await picker.pickImage(
          source: source,
          maxWidth: 800,
          maxHeight: 800,
          imageQuality: 80,
        );

        if (image != null) {
          imageBytes = await image.readAsBytes();
          base64Image = base64Encode(imageBytes);
        }
      } else {
        // Desktop - use file picker
        FilePickerResult? result = await FilePicker.platform.pickFiles(
          type: FileType.image,
          allowMultiple: false,
        );

        if (result != null && result.files.single.path != null) {
          final File imageFile = File(result.files.single.path!);
          imageBytes = await imageFile.readAsBytes();
          base64Image = base64Encode(imageBytes);
        }
      }

      if (base64Image != null && imageBytes != null) {
        setState(() {
          _base64Image = base64Image;
          _imageBytes = imageBytes;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to pick image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<ImageSource?> _showImageSourceDialog() async {
    return showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Image Source'),
        content: const Text('Choose where to get the image from'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, ImageSource.camera),
            child: const Text('Camera'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, ImageSource.gallery),
            child: const Text('Gallery'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _removeImage() {
    setState(() {
      _base64Image = null;
      _imageBytes = null;
    });
  }

  void _updateAvailableQuantity() {
    if (_selectedItemId != null && _selectedLocationId != null) {
      final itemsProvider = Provider.of<ItemsProvider>(context, listen: false);
      final item = itemsProvider.allItems.firstWhere(
            (item) => item.id == _selectedItemId,
        orElse: () => Item(id: '', name: '', locations: []),
      );

      final location = item.locations.firstWhere(
            (loc) => loc.locationId == _selectedLocationId,
        orElse: () => ItemLocation(locationId: '', name: '', quantity: 0),
      );

      setState(() {
        _availableQuantity = location.quantity;
      });
    } else {
      setState(() {
        _availableQuantity = 0;
      });
    }
  }

  List<Location> _getAvailableLocationsForItem() {
    if (_selectedItemId == null) return [];

    final itemsProvider = Provider.of<ItemsProvider>(context, listen: false);
    final item = itemsProvider.allItems.firstWhere(
          (item) => item.id == _selectedItemId,
      orElse: () => Item(id: '', name: '', locations: []),
    );

    final itemsProviderLocations = itemsProvider.locations;

    return itemsProviderLocations.where((location) {
      return item.locations.any((itemLoc) =>
      itemLoc.locationId == location.id && itemLoc.quantity > 0);
    }).toList();
  }

  Future<void> _submitRepairRequest() async {
    // 1. Validate Form Fields (Serial number is now part of this)
    if (!_formKey.currentState!.validate()) return;

    // 2. Validate Item Selection
    if (_selectedItemId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an item')),
      );
      return;
    }

    // 3. Validate Location Selection
    if (_selectedLocationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a location')),
      );
      return;
    }

    // 4. Validate Photo (Now Mandatory)
    if (_base64Image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A photo of the item is required for repairs'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // 5. Validate Quantity Logic
    final quantity = int.tryParse(_quantityController.text) ?? 0;
    if (quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid quantity')),
      );
      return;
    }

    if (quantity > _availableQuantity) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Quantity cannot exceed available stock ($_availableQuantity)')),
      );
      return;
    }

    // 6. Submit Data
    final repairProvider = Provider.of<RepairProvider>(context, listen: false);

    final success = await repairProvider.sendToRepair(
      itemId: _selectedItemId!,
      locationId: _selectedLocationId!,
      quantity: quantity,
      vendorName: _vendorNameController.text,
      serialNumber: _serialNumberController.text, // Guaranteed not to be empty by validator
      note: _noteController.text.isNotEmpty ? _noteController.text : null,
      photo: _base64Image,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Item sent for repair successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      await _refreshData();
      _resetForm();
    }
  }

  @override
  void dispose() {
    _vendorNameController.dispose();
    _serialNumberController.dispose();
    _noteController.dispose();
    _quantityController.dispose();
    _barcodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Send to Repair'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      body: Consumer<ItemsProvider>(
        builder: (context, itemsProvider, child) {
          return Consumer<RepairProvider>(
            builder: (context, repairProvider, child) {
              if (_isInitialLoading || itemsProvider.isLoading || itemsProvider.locationsLoading) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Loading items and locations...'),
                    ],
                  ),
                );
              }

              if (repairProvider.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildRefreshSection(itemsProvider),
                        const SizedBox(height: 20),

                        // Item Selection Section
                        _buildItemSelectionSection(itemsProvider),
                        const SizedBox(height: 20),

                        // Location Selection
                        _buildLocationDropdown(itemsProvider),
                        const SizedBox(height: 20),

                        if (_availableQuantity > 0)
                          _buildAvailableQuantity(),
                        const SizedBox(height: 20),

                        _buildVendorNameField(),
                        const SizedBox(height: 20),
                        _buildQuantityField(),
                        const SizedBox(height: 20),

                        // Serial Number (Now Mandatory)
                        _buildSerialNumberField(),
                        const SizedBox(height: 20),

                        // Photo (Now Mandatory)
                        _buildPhotoSection(),
                        const SizedBox(height: 20),

                        _buildNoteField(),
                        const SizedBox(height: 30),

                        if (repairProvider.error.isNotEmpty)
                          _buildErrorWidget(repairProvider),
                        _buildSubmitButton(repairProvider),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildItemSelectionSection(ItemsProvider itemsProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Item *',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),

        // Barcode Search Section
        Card(
          elevation: 1,
          color: Colors.grey[50],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey[300]!),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.qr_code_scanner, color: Colors.purple, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Scan or Enter Barcode',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Barcode Input with Actions
                Stack(
                  children: [
                    TextFormField(
                      controller: _barcodeController,
                      decoration: InputDecoration(
                        labelText: 'Barcode',
                        prefixIcon: const Icon(Icons.qr_code_2_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        hintText: 'Enter barcode or scan',
                        suffixIcon: _barcodeController.text.isNotEmpty
                            ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: _clearBarcodeSearch,
                        )
                            : null,
                      ),
                      onChanged: (value) {
                        if (value.isEmpty) {
                          setState(() {
                            _barcodeSearchError = null;
                          });
                        }
                      },
                      onFieldSubmitted: (value) {
                        if (value.isNotEmpty) {
                          _searchItemByBarcode(value);
                        }
                      },
                    ),
                    if (_barcodeController.text.isEmpty)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: ElevatedButton.icon(
                          onPressed: _isScanningBarcode ? null : _scanBarcode,
                          icon: const Icon(Icons.camera_alt, size: 16),
                          label: const Text('Scan'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            backgroundColor: Colors.purple.shade50,
                            foregroundColor: Colors.purple.shade700,
                            textStyle: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                  ],
                ),

                // Search Button
                if (_barcodeController.text.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isScanningBarcode ? null : () => _searchItemByBarcode(_barcodeController.text),
                      icon: _isScanningBarcode
                          ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                          : const Icon(Icons.search, size: 16),
                      label: Text(_isScanningBarcode ? 'Searching...' : 'Search Item'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple.shade600,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],

                // Barcode Search Result/Error
                if (_barcodeSearchError != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red.shade600, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _barcodeSearchError!,
                            style: TextStyle(
                              color: Colors.red.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Success message when item is found via barcode
                if (_selectedItemId != null && _barcodeController.text.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green.shade600, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Item selected via barcode',
                            style: TextStyle(
                              color: Colors.green.shade600,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Divider with "OR"
        Row(
          children: [
            Expanded(
              child: Divider(color: Colors.grey[400]),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'OR',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Expanded(
              child: Divider(color: Colors.grey[400]),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Dropdown Selection
        _buildItemDropdown(itemsProvider),
      ],
    );
  }

  Widget _buildPhotoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Repair Photo *',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        if (_imageBytes != null)
          _buildImagePreview()
        else
          _buildImagePickerButton(),
      ],
    );
  }

  Widget _buildImagePickerButton() {
    return OutlinedButton.icon(
      onPressed: _pickImage,
      icon: const Icon(Icons.photo_library),
      label: Text(
        Platform.isAndroid || Platform.isIOS
            ? 'Take Photo or Choose from Gallery'
            : 'Choose Image from Files',
      ),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 50),
      ),
    );
  }

  Widget _buildImagePreview() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          height: 200,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.memory(
              _imageBytes!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const Center(
                  child: Icon(Icons.error, color: Colors.red, size: 50),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _removeImage,
          icon: const Icon(Icons.delete, color: Colors.red),
          label: const Text('Remove Photo', style: TextStyle(color: Colors.red)),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: Colors.red.shade300),
          ),
        ),
      ],
    );
  }

  Widget _buildRefreshSection(ItemsProvider itemsProvider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Items: ${itemsProvider.allItems.length}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              Text(
                'Locations: ${itemsProvider.locations.length}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
        OutlinedButton.icon(
          onPressed: _refreshData,
          icon: const Icon(Icons.refresh, size: 16),
          label: const Text('Refresh'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
      ],
    );
  }

  Widget _buildItemDropdown(ItemsProvider itemsProvider) {
    final itemsWithStock = itemsProvider.allItems
        .where((item) => item.totalStock != null && item.totalStock! > 0)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select from List',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedItemId,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            hintText: itemsWithStock.isEmpty ? 'No items with stock' : 'Choose an item',
            suffixIcon: itemsWithStock.isNotEmpty && _selectedItemId != null
                ? IconButton(
              icon: const Icon(Icons.clear, size: 16),
              onPressed: () {
                setState(() {
                  _selectedItemId = null;
                  _selectedLocationId = null;
                  _availableQuantity = 0;
                  _quantityController.clear();
                  _barcodeController.clear();
                  _barcodeSearchError = null;
                });
              },
            )
                : null,
          ),
          items: itemsWithStock.map((item) {
            return DropdownMenuItem<String>(
              value: item.id,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  // Text(
                  //   'SKU: ${item.sku ?? "N/A"} | Stock: ${item.totalStock ?? 0} ${item.unit ?? ""}',
                  //   style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  // ),
                ],
              ),
            );
          }).toList(),
          onChanged: itemsWithStock.isEmpty ? null : (value) {
            setState(() {
              _selectedItemId = value;
              _selectedLocationId = null;
              _availableQuantity = 0;
              _quantityController.clear();
              // Clear barcode search when selecting from dropdown
              _barcodeController.clear();
              _barcodeSearchError = null;
            });
            _updateAvailableQuantity();
          },
          validator: (value) {
            if (value == null && itemsWithStock.isNotEmpty) {
              return 'Please select an item';
            }
            return null;
          },
        ),
        if (itemsWithStock.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              'No items available with stock. Please add stock first.',
              style: TextStyle(color: Colors.orange.shade700, fontSize: 14),
            ),
          ),
      ],
    );
  }

  Widget _buildLocationDropdown(ItemsProvider itemsProvider) {
    final availableLocations = _getAvailableLocationsForItem();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Location *',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedLocationId,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            hintText: availableLocations.isEmpty ? 'No locations with stock' : 'Choose a location',
            suffixIcon: availableLocations.isNotEmpty && _selectedLocationId != null
                ? IconButton(
              icon: const Icon(Icons.clear, size: 16),
              onPressed: () {
                setState(() {
                  _selectedLocationId = null;
                  _availableQuantity = 0;
                  _quantityController.clear();
                });
              },
            )
                : null,
          ),
          items: availableLocations.map((location) {
            final item = itemsProvider.allItems.firstWhere(
                  (item) => item.id == _selectedItemId,
              orElse: () => Item(id: '', name: '', locations: []),
            );
            final itemLocation = item.locations.firstWhere(
                  (loc) => loc.locationId == location.id,
              orElse: () => ItemLocation(locationId: '', name: '', quantity: 0),
            );

            return DropdownMenuItem<String>(
              value: location.id,
              child: Text('${location.name} (Available: ${itemLocation.quantity})'),
            );
          }).toList(),
          onChanged: availableLocations.isEmpty ? null : (value) {
            setState(() {
              _selectedLocationId = value;
            });
            _updateAvailableQuantity();
          },
          validator: (value) {
            if (value == null && availableLocations.isNotEmpty) {
              return 'Please select a location';
            }
            return null;
          },
        ),
        if (_selectedItemId != null && availableLocations.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              'Selected item has no stock in any location.',
              style: TextStyle(color: Colors.orange.shade700, fontSize: 14),
            ),
          ),
      ],
    );
  }

  Widget _buildAvailableQuantity() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.inventory_2, color: Colors.blue.shade700, size: 20),
          const SizedBox(width: 8),
          Text(
            'Available Quantity: $_availableQuantity',
            style: TextStyle(
              color: Colors.blue.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVendorNameField() {
    return TextFormField(
      controller: _vendorNameController,
      decoration: const InputDecoration(
        labelText: 'Vendor Name *',
        border: OutlineInputBorder(),
        hintText: 'Enter repair vendor name',
        prefixIcon: Icon(Icons.business),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter vendor name';
        }
        return null;
      },
    );
  }

  Widget _buildQuantityField() {
    return TextFormField(
      controller: _quantityController,
      decoration: InputDecoration(
        labelText: 'Quantity *',
        border: const OutlineInputBorder(),
        hintText: 'Enter quantity to send for repair',
        prefixIcon: const Icon(Icons.format_list_numbered),
        suffixIcon: _availableQuantity > 0
            ? IconButton(
          icon: const Icon(Icons.all_inclusive, size: 16),
          onPressed: () {
            setState(() {
              _quantityController.text = _availableQuantity.toString();
            });
          },
          tooltip: 'Use all available quantity',
        )
            : null,
      ),
      keyboardType: TextInputType.number,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter quantity';
        }
        final quantity = int.tryParse(value);
        if (quantity == null || quantity <= 0) {
          return 'Please enter a valid quantity';
        }
        if (quantity > _availableQuantity) {
          return 'Quantity cannot exceed available stock';
        }
        return null;
      },
    );
  }

  Widget _buildSerialNumberField() {
    return TextFormField(
      controller: _serialNumberController,
      decoration: const InputDecoration(
        labelText: 'Serial Number *',
        border: OutlineInputBorder(),
        hintText: 'Enter item serial number',
        prefixIcon: Icon(Icons.confirmation_number),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter serial number';
        }
        return null;
      },
    );
  }

  Widget _buildNoteField() {
    return TextFormField(
      controller: _noteController,
      decoration: const InputDecoration(
        labelText: 'Repair Notes (Optional)',
        border: OutlineInputBorder(),
        hintText: 'Enter repair details or issues',
        prefixIcon: Icon(Icons.note),
      ),
      maxLines: 3,
    );
  }

  Widget _buildErrorWidget(RepairProvider repairProvider) {
    return Container(
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
              repairProvider.error,
              style: TextStyle(color: Colors.red.shade600),
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, color: Colors.red.shade600, size: 20),
            onPressed: () => repairProvider.clearError(),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(RepairProvider repairProvider) {
    final itemsWithStock = Provider.of<ItemsProvider>(context, listen: false)
        .allItems
        .where((item) => item.totalStock != null && item.totalStock! > 0)
        .isNotEmpty;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: (itemsWithStock && !_isScanningBarcode) ? _submitRepairRequest : null,
        icon: const Icon(Icons.build_circle),
        label: const Text(
          'Send for Repair',
          style: TextStyle(fontSize: 16),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.purple,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}