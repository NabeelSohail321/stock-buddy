import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/item_model.dart';
import '../../models/location_model.dart';
import '../../models/stock_model.dart';
import '../../providers/items_provider.dart';
import '../../services/image_service.dart';
import '../items/barcode_scanner_screen.dart';

class AddStockScreen extends StatefulWidget {
  const AddStockScreen({super.key});

  @override
  State<AddStockScreen> createState() => _AddStockScreenState();
}

class _AddStockScreenState extends State<AddStockScreen> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _noteController = TextEditingController();
  final _barcodeController = TextEditingController();

  String? _selectedItemId;
  String? _selectedLocationId;
  String? _selectedImageBase64;
  final ImageService _imageService = ImageService();

  bool _isScanningBarcode = false;
  String? _barcodeSearchError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final itemsProvider = context.read<ItemsProvider>();
    await itemsProvider.fetchItems();
    await itemsProvider.fetchLocations();
  }

  Future<void> _addStock() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedItemId == null) {
        _showError('Please select an item');
        return;
      }
      if (_selectedLocationId == null) {
        _showError('Please select a location');
        return;
      }

      final quantity = int.tryParse(_quantityController.text) ?? 0;
      if (quantity <= 0) {
        _showError('Please enter a valid quantity greater than 0');
        return;
      }

      final itemsProvider = context.read<ItemsProvider>();

      final request = StockAddRequest(
        itemId: _selectedItemId!,
        locationId: _selectedLocationId!,
        quantity: quantity,
        note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
        photo: _selectedImageBase64,
      );

      final success = await itemsProvider.addStock(request);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Stock added successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        _resetForm();
      }
    }
  }

  void _resetForm() {
    _formKey.currentState!.reset();
    setState(() {
      _selectedItemId = null;
      _selectedLocationId = null;
      _selectedImageBase64 = null;
      _barcodeController.clear();
      _barcodeSearchError = null;
    });
    _quantityController.clear();
    _noteController.clear();
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
      final base64Image = await _imageService.pickAndConvertImage();
      if (base64Image != null && mounted) {
        setState(() {
          _selectedImageBase64 = base64Image;
        });
      }
    } catch (e) {
      if (mounted) {
        _showError('Failed to pick image: $e');
      }
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImageBase64 = null;
    });
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

    final itemsProvider = context.read<ItemsProvider>();

    try {
      final item = await itemsProvider.getItemByBarcode(barcode);

      if (item != null && mounted) {
        setState(() {
          _selectedItemId = item.id;
          _barcodeSearchError = null;
        });

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
    });
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _noteController.dispose();
    _barcodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final itemsProvider = context.watch<ItemsProvider>();
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width >= 768;

    final isLoading = itemsProvider.isLoading || itemsProvider.locationsLoading || _isScanningBarcode;
    final hasError = itemsProvider.errorMessage.isNotEmpty || itemsProvider.locationsErrorMessage.isNotEmpty;

    // Improved loading state
    if (isLoading && (itemsProvider.items.isEmpty || itemsProvider.locations.isEmpty)) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Don't show form if no data is available
    if (itemsProvider.items.isEmpty || itemsProvider.locations.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Add Stock'),
          backgroundColor: Colors.blue.shade800,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'No items or locations available',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Add Stock'),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
        actions: [
          if (isLoading)
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
      body: SafeArea(
        child: Column(
          children: [
            // Error Messages at the top
            if (hasError) ...[
              if (itemsProvider.errorMessage.isNotEmpty)
                _buildErrorContainer(itemsProvider.errorMessage, () => itemsProvider.clearError()),
              if (itemsProvider.locationsErrorMessage.isNotEmpty)
                _buildErrorContainer(itemsProvider.locationsErrorMessage, () => itemsProvider.clearLocationsError()),
            ],

            // Main content area
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 24 : 16,
                  vertical: 16,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildFormCard(itemsProvider, isDesktop),
                      const SizedBox(height: 24),
                      // _buildImageCard(isDesktop),
                      const SizedBox(height: 32),
                      _buildSubmitButton(isLoading),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormCard(ItemsProvider itemsProvider, bool isDesktop) {
    return Card(
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
              'Stock Information',
              style: TextStyle(
                fontSize: isDesktop ? 20 : 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 20),

            // Item Selection Section
            _buildItemSelectionSection(itemsProvider),
            const SizedBox(height: 16),

            // Location Selection
            _buildLocationDropdown(itemsProvider),
            const SizedBox(height: 16),

            // Quantity
            TextFormField(
              controller: _quantityController,
              decoration: InputDecoration(
                labelText: 'Quantity *',
                prefixIcon: const Icon(Icons.numbers_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                hintText: 'Enter quantity to add',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter quantity';
                }
                final quantity = int.tryParse(value);
                if (quantity == null || quantity <= 0) {
                  return 'Please enter a valid quantity greater than 0';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Note
            TextFormField(
              controller: _noteController,
              decoration: InputDecoration(
                labelText: 'Note (Optional)',
                prefixIcon: const Icon(Icons.note_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                hintText: 'e.g., Initial stock, Restock, etc.',
              ),
              maxLines: 3,
            ),
          ],
        ),
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
                    const Icon(Icons.qr_code_scanner, color: Colors.blue, size: 20),
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
                            backgroundColor: Colors.blue.shade50,
                            foregroundColor: Colors.blue.shade700,
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
                        backgroundColor: Colors.blue.shade600,
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

  Widget _buildItemDropdown(ItemsProvider itemsProvider) {
    final items = itemsProvider.items;

    // Ensure we have a valid value
    final validValue = items.any((item) => item.id == _selectedItemId)
        ? _selectedItemId
        : null;

    return Container(
      width: double.infinity,
      child: DropdownButtonFormField<String>(
        value: validValue,
        decoration: InputDecoration(
          labelText: 'Select from List',
          prefixIcon: const Icon(Icons.list_alt_outlined),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        ),
        items: [
          const DropdownMenuItem<String>(
            value: null,
            child: Text('Select an item', style: TextStyle(color: Colors.grey)),
          ),
          ...items.map((item) => DropdownMenuItem<String>(
            value: item.id,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                // if (item.sku != null && item.sku!.isNotEmpty)
                //   Text(
                //     'SKU: ${item.sku}',
                //     style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                //   ),
                // if (item.barcode != null && item.barcode!.isNotEmpty)
                //   Text(
                //     'Barcode: ${item.barcode}',
                //     style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                //   ),
              ],
            ),
          )).toList(),
        ],
        onChanged: (value) {
          setState(() {
            _selectedItemId = value;
            // Clear barcode search when selecting from dropdown
            _barcodeController.clear();
            _barcodeSearchError = null;
          });
        },
        validator: (value) {
          if (value == null) {
            return 'Please select an item';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildImageCard(bool isDesktop) {
    return Card(
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
              'Item Photo (Optional)',
              style: TextStyle(
                fontSize: isDesktop ? 20 : 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add a photo of the item or stock receipt',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),

            // Image Preview and Upload Button
            if (_selectedImageBase64 != null)
              Column(
                children: [
                  Container(
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: _imageService.imageFromBase64(
                        _selectedImageBase64!,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _removeImage,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                      child: const Text('Remove Photo'),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),

            // Upload Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _pickImage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade50,
                      foregroundColor: Colors.blue.shade800,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Gallery'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _pickImage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade50,
                      foregroundColor: Colors.green.shade800,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Camera'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton(bool isLoading) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: isLoading ? null : _addStock,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue.shade800,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: isLoading
            ? const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation(Colors.white),
          ),
        )
            : const Text(
          'Add Stock',
          style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.white
          ),
        ),
      ),
    );
  }

  Widget _buildLocationDropdown(ItemsProvider itemsProvider) {
    final locations = itemsProvider.locations;

    // Ensure we have a valid value
    final validValue = locations.any((location) => location.id == _selectedLocationId)
        ? _selectedLocationId
        : null;

    return Container(
      width: double.infinity,
      child: DropdownButtonFormField<String>(
        value: validValue,
        decoration: InputDecoration(
          labelText: 'Select Location *',
          prefixIcon: const Icon(Icons.location_on_outlined),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        ),
        items: [
          const DropdownMenuItem<String>(
            value: null,
            child: Text('Select a location', style: TextStyle(color: Colors.grey)),
          ),
          ...locations.map((location) => DropdownMenuItem<String>(
            value: location.id,
            child: Text(
              location.name,
              style: const TextStyle(fontSize: 14),
            ),
          )).toList(),
        ],
        onChanged: (value) {
          setState(() {
            _selectedLocationId = value;
          });
        },
        validator: (value) {
          if (value == null) {
            return 'Please select a location';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildErrorContainer(String message, VoidCallback onClear) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 8),
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
              message,
              style: TextStyle(color: Colors.red.shade600),
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, color: Colors.red.shade600, size: 20),
            onPressed: onClear,
          ),
        ],
      ),
    );
  }
}