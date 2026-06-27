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
  final _modelNumberController = TextEditingController();
  final _serialNumberController = TextEditingController();
  final _purchaseDateController = TextEditingController();

  String _selectedUnit = 'pcs';
  String _selectedStatus = 'active';

  final List<String> _units = [
    'pcs', 'kg', 'g', 'lb', 'oz', 'L', 'mL', 'm', 'cm', 'mm',
    'box', 'pack', 'bottle', 'can',
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
    _modelNumberController.text = widget.item.modelNumber ?? '';
    _serialNumberController.text = widget.item.serialNumber ?? '';
    _purchaseDateController.text = widget.item.purchaseDate != null
        ? widget.item.purchaseDate!.toString().split(' ')[0]
        : '';

    final itemUnit = widget.item.unit ?? 'pcs';
    if (_units.contains(itemUnit)) {
      _selectedUnit = itemUnit;
    } else {
      _units.add(itemUnit);
      _selectedUnit = itemUnit;
    }

    final itemStatus = widget.item.effectiveStatus;
    if (itemStatus == 'active' || itemStatus == 'sufficient' || itemStatus == 'in_stock') {
      _selectedStatus = 'active';
    } else {
      _selectedStatus = 'inactive';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _skuController.dispose();
    _barcodeController.dispose();
    _thresholdController.dispose();
    _modelNumberController.dispose();
    _serialNumberController.dispose();
    _purchaseDateController.dispose();
    super.dispose();
  }

  Future<void> _selectPurchaseDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: widget.item.purchaseDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(
            primary: Colors.blue.shade800,
            onPrimary: Colors.white,
            onSurface: Colors.black,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _purchaseDateController.text = picked.toString().split(' ')[0];
      });
    }
  }

  Future<void> _updateItem() async {
    if (!_formKey.currentState!.validate()) return;

    final itemsProvider = context.read<ItemsProvider>();

    // Handle barcode change separately via assignBarcode endpoint.
    final newBarcode = _barcodeController.text.trim();
    if (newBarcode != (widget.item.barcode ?? '')) {
      final barcodeSuccess = await itemsProvider.assignBarcode(
        itemId: widget.item.id,
        barcode: newBarcode.isEmpty ? null : newBarcode,
        overwrite: true,
      );
      if (!barcodeSuccess && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update barcode: ${itemsProvider.errorMessage}'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    final success = await itemsProvider.updateItem(
      id: widget.item.id,
      name: _nameController.text.trim(),
      unit: _selectedUnit,
      threshold: int.tryParse(_thresholdController.text) ?? 0,
      status: _selectedStatus,
      modelNumber: _modelNumberController.text.trim(),
      serialNumber: _serialNumberController.text.trim(),
      purchaseDate: _purchaseDateController.text.trim(),
    );

    if (!mounted) return;
    if (success) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item updated successfully'), backgroundColor: Colors.green),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update: ${itemsProvider.errorMessage}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final itemsProvider = context.watch<ItemsProvider>();
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width >= 768;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Edit Item'),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
        actions: [
          if (itemsProvider.isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.save),
              tooltip: 'Save',
              onPressed: _updateItem,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: isDesktop ? 24 : 16, vertical: 16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Error banner
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
                        child: Text(itemsProvider.errorMessage,
                            style: TextStyle(color: Colors.red.shade600)),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: Colors.red.shade600, size: 20),
                        onPressed: () => itemsProvider.clearError(),
                      ),
                    ],
                  ),
                ),

              // Item Details card
              Card(
                elevation: 2,
                shadowColor: Colors.black12,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Item Details',
                          style: TextStyle(
                            fontSize: isDesktop ? 20 : 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          )),
                      const SizedBox(height: 20),

                      // Name
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Item Name *',
                          prefixIcon: const Icon(Icons.inventory_2_outlined),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Please enter item name' : null,
                      ),
                      const SizedBox(height: 16),

                      // SKU (read-only)
                      TextFormField(
                        controller: _skuController,
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: 'SKU (auto-generated)',
                          prefixIcon: const Icon(Icons.tag_outlined),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          fillColor: Colors.grey.shade100,
                          filled: true,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Barcode
                      TextFormField(
                        controller: _barcodeController,
                        decoration: InputDecoration(
                          labelText: 'Barcode',
                          prefixIcon: const Icon(Icons.qr_code_outlined),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Model & Serial (side by side on desktop)
                      if (isDesktop)
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _modelNumberController,
                                decoration: InputDecoration(
                                  labelText: 'Model Number',
                                  prefixIcon: const Icon(Icons.computer_outlined),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: _serialNumberController,
                                decoration: InputDecoration(
                                  labelText: 'Serial Number',
                                  prefixIcon: const Icon(Icons.numbers_outlined),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                          ],
                        )
                      else
                        Column(
                          children: [
                            TextFormField(
                              controller: _modelNumberController,
                              decoration: InputDecoration(
                                labelText: 'Model Number',
                                prefixIcon: const Icon(Icons.computer_outlined),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _serialNumberController,
                              decoration: InputDecoration(
                                labelText: 'Serial Number',
                                prefixIcon: const Icon(Icons.numbers_outlined),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 16),

                      // Purchase Date
                      TextFormField(
                        controller: _purchaseDateController,
                        readOnly: true,
                        onTap: _selectPurchaseDate,
                        decoration: InputDecoration(
                          labelText: 'Purchase Date',
                          prefixIcon: const Icon(Icons.calendar_today_outlined),
                          suffixIcon: _purchaseDateController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () => setState(() => _purchaseDateController.clear()),
                                )
                              : const Icon(Icons.arrow_drop_down),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          hintText: 'Select purchase date',
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Unit & Threshold (side by side on desktop)
                      if (isDesktop)
                        Row(
                          children: [
                            Expanded(flex: 2, child: _buildUnitDropdown()),
                            const SizedBox(width: 16),
                            Expanded(flex: 1, child: _buildThresholdField()),
                          ],
                        )
                      else
                        Column(
                          children: [
                            _buildUnitDropdown(),
                            const SizedBox(height: 16),
                            _buildThresholdField(),
                          ],
                        ),
                      const SizedBox(height: 16),

                      // Status
                      DropdownButtonFormField<String>(
                        value: _selectedStatus,
                        decoration: InputDecoration(
                          labelText: 'Status *',
                          prefixIcon: const Icon(Icons.toggle_on_outlined),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        items: [
                          DropdownMenuItem(
                            value: 'active',
                            child: Row(children: [
                              const Icon(Icons.check_circle, color: Colors.green, size: 18),
                              const SizedBox(width: 8),
                              const Text('Active'),
                            ]),
                          ),
                          DropdownMenuItem(
                            value: 'inactive',
                            child: Row(children: [
                              const Icon(Icons.remove_circle, color: Colors.orange, size: 18),
                              const SizedBox(width: 8),
                              const Text('Inactive'),
                            ]),
                          ),
                        ],
                        onChanged: (v) => setState(() => _selectedStatus = v!),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Save button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: itemsProvider.isLoading ? null : _updateItem,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade800,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: itemsProvider.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)),
                        )
                      : const Text('Save Changes',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
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
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      items: _units
          .map((u) => DropdownMenuItem<String>(value: u, child: Text(u.toUpperCase())))
          .toList(),
      onChanged: (v) => setState(() => _selectedUnit = v!),
      validator: (v) => (v == null || v.isEmpty) ? 'Please select a unit' : null,
    );
  }

  Widget _buildThresholdField() {
    return TextFormField(
      controller: _thresholdController,
      decoration: InputDecoration(
        labelText: 'Low Stock Threshold *',
        prefixIcon: const Icon(Icons.warning_amber_outlined),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      keyboardType: TextInputType.number,
      validator: (v) {
        if (v == null || v.isEmpty) return 'Please enter threshold';
        final n = int.tryParse(v);
        if (n == null || n < 0) return 'Enter a valid number';
        return null;
      },
    );
  }
}
