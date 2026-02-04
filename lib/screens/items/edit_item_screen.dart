import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stock_buddy/models/item_model.dart';
import 'package:stock_buddy/providers/items_provider.dart';

class EditItemScreen extends StatefulWidget {
  final Item item;

  const EditItemScreen({super.key, required this.item});

  @override
  State<EditItemScreen> createState() => _EditItemScreenState();
}

class _EditItemScreenState extends State<EditItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _skuController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _thresholdController = TextEditingController();

  String _selectedUnit = 'pieces';
  String _selectedStatus = 'active';

  // Common unit options that match both 'pcs' and 'pieces'
  final List<String> _unitOptions = [
    'pieces', 'pcs', 'units', 'kg', 'grams', 'liters', 'meters', 'boxes', 'packs'
  ];

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    _nameController.text = widget.item.name;
    _skuController.text = widget.item.sku ?? '';
    _barcodeController.text = widget.item.barcode ?? '';
    _thresholdController.text = widget.item.threshold?.toString() ?? '0';

    // Handle unit conversion - if item has 'pcs', use 'pieces' or add to options
    final itemUnit = widget.item.unit ?? 'pieces';
    if (_unitOptions.contains(itemUnit)) {
      _selectedUnit = itemUnit;
    } else {
      // If the unit from API is not in our options, add it temporarily
      _unitOptions.add(itemUnit);
      _selectedUnit = itemUnit;
    }

    // Use the effective status from the item model
    final itemStatus = widget.item.effectiveStatus;

    // Map to standard active/inactive for the dropdown
    if (itemStatus == 'active' ||
        itemStatus == 'sufficient' ||
        itemStatus == 'in_stock') {
      _selectedStatus = 'active';
    } else if (itemStatus == 'inactive' ||
        itemStatus == 'discontinued' ||
        itemStatus == 'out_of_stock') {
      _selectedStatus = 'inactive';
    } else {
      _selectedStatus = 'active'; // Default to active for unknown statuses
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _skuController.dispose();
    _barcodeController.dispose();
    _thresholdController.dispose();
    super.dispose();
  }

  Future<void> _updateItem() async {
    if (_formKey.currentState!.validate()) {
      final itemsProvider = context.read<ItemsProvider>();

      final success = await itemsProvider.updateItem(
        id: widget.item.id,
        name: _nameController.text.trim(),
        unit: _selectedUnit,
        threshold: int.tryParse(_thresholdController.text) ?? 0,
        status: _selectedStatus,
      );

      if (success && mounted) {
        Navigator.pop(context, true); // Return true to indicate success
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Item updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update item: ${itemsProvider.errorMessage}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Item'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _updateItem,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Item Name *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter item name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _skuController,
                decoration: const InputDecoration(
                  labelText: 'SKU',
                  border: OutlineInputBorder(),
                ),
                readOnly: true, // SKU should not be editable
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _barcodeController,
                decoration: const InputDecoration(
                  labelText: 'Barcode',
                  border: OutlineInputBorder(),
                ),
                readOnly: true, // Barcode should be managed separately
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedUnit,
                decoration: const InputDecoration(
                  labelText: 'Unit *',
                  border: OutlineInputBorder(),
                ),
                items: _unitOptions.map((unit) => DropdownMenuItem(
                  value: unit,
                  child: Text(unit),
                )).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedUnit = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _thresholdController,
                decoration: const InputDecoration(
                  labelText: 'Low Stock Threshold *',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter threshold';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedStatus,
                decoration: const InputDecoration(
                  labelText: 'Status *',
                  border: OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem(
                    value: 'active',
                    child: Row(
                      children: const [
                        Icon(Icons.check_circle, color: Colors.green),
                        SizedBox(width: 8),
                        Text('Active'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'inactive',
                    child: Row(
                      children: const [
                        Icon(Icons.remove_circle, color: Colors.orange),
                        SizedBox(width: 8),
                        Text('Inactive'),
                      ],
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedStatus = value!;
                  });
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _updateItem,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.orange,
                  ),
                  child: const Text(
                    'Update Item',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}