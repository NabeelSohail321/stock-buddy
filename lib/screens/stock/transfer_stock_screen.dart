import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/items_provider.dart';
import '../../providers/manager_provider.dart';
import '../../providers/stock_transfer_provider.dart';
import '../../models/item_model.dart';
import '../../models/location_model.dart';
import '../items/barcode_scanner_screen.dart';

class TransferStockScreen extends StatefulWidget {
  const TransferStockScreen({super.key});

  @override
  State<TransferStockScreen> createState() => _TransferStockScreenState();
}

class _TransferStockScreenState extends State<TransferStockScreen> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _noteController = TextEditingController();
  final _barcodeController = TextEditingController();

  String? _selectedItemId;
  String? _selectedFromLocationId;
  String? _selectedToLocationId;
  String? _selectedManagerId;

  bool _isScanningBarcode = false;
  String? _barcodeSearchError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  void _loadData() {
    final itemsProvider = context.read<ItemsProvider>();
    itemsProvider.fetchItems();
    itemsProvider.fetchLocations();
    context.read<ManagerProvider>().fetchManagers();
  }

  Future<void> _transferStock() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedItemId == null) { _showError('Please select an item'); return; }
    if (_selectedFromLocationId == null) { _showError('Please select source location'); return; }
    if (_selectedToLocationId == null) { _showError('Please select destination location'); return; }
    if (_selectedFromLocationId == _selectedToLocationId) {
      _showError('Source and destination locations cannot be the same');
      return;
    }

    final quantity = int.tryParse(_quantityController.text) ?? 0;
    if (quantity <= 0) { _showError('Please enter a valid quantity greater than 0'); return; }

    final itemsProvider = context.read<ItemsProvider>();
    final selectedItem = itemsProvider.allItems.firstWhere(
      (item) => item.id == _selectedItemId,
      orElse: () => Item(id: '', name: '', locations: []),
    );
    final sourceLocation = selectedItem.locations.firstWhere(
      (loc) => loc.locationId == _selectedFromLocationId,
      orElse: () => ItemLocation(locationId: '', quantity: 0, name: ''),
    );
    if (sourceLocation.quantity < quantity) {
      _showError('Insufficient stock at source. Available: ${sourceLocation.quantity}');
      return;
    }

    final success = await context.read<StockTransferProvider>().transferStock(
      itemId: _selectedItemId!,
      fromLocationId: _selectedFromLocationId!,
      toLocationId: _selectedToLocationId!,
      quantity: quantity,
      managerId: _selectedManagerId,
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Stock transfer initiated successfully!'), backgroundColor: Colors.green),
      );
      _resetForm();
    }
  }

  void _resetForm() {
    _formKey.currentState!.reset();
    setState(() {
      _selectedItemId = null;
      _selectedFromLocationId = null;
      _selectedToLocationId = null;
      _selectedManagerId = null;
      _barcodeController.clear();
      _barcodeSearchError = null;
    });
    _quantityController.clear();
    _noteController.clear();
    context.read<StockTransferProvider>().clearAllMessages();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> _scanBarcode() async {
    setState(() => _isScanningBarcode = true);
    try {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
      );
      if (result != null && result is String) {
        _barcodeController.text = result;
        await _searchItemByBarcode(result);
      }
    } catch (e) {
      _showError('Failed to scan barcode: $e');
    } finally {
      if (mounted) setState(() => _isScanningBarcode = false);
    }
  }

  Future<void> _searchItemByBarcode(String barcode) async {
    if (barcode.isEmpty) return;
    setState(() => _barcodeSearchError = null);
    try {
      final item = await context.read<ItemsProvider>().getItemByBarcode(barcode);
      if (item != null && mounted) {
        setState(() {
          _selectedItemId = item.id;
          _selectedFromLocationId = null;
          _selectedToLocationId = null;
          _selectedManagerId = null;
          _barcodeSearchError = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Item found: ${item.name}'), backgroundColor: Colors.green, duration: const Duration(seconds: 2)),
        );
      } else {
        setState(() => _barcodeSearchError = 'No item found with barcode: $barcode');
      }
    } catch (e) {
      setState(() => _barcodeSearchError = 'Error searching item: ${e.toString().replaceAll('Exception: ', '')}');
    }
  }

  void _clearBarcodeSearch() {
    setState(() {
      _barcodeController.clear();
      _barcodeSearchError = null;
      _selectedItemId = null;
      _selectedFromLocationId = null;
      _selectedToLocationId = null;
      _selectedManagerId = null;
    });
  }

  void _onFromLocationChanged(String? locationId) {
    setState(() {
      _selectedFromLocationId = locationId;
      _selectedToLocationId = null;
      _selectedManagerId = null;
    });
    if (locationId != null) {
      context.read<ManagerProvider>().fetchManagersByLocation(locationId);
    }
  }

  List<ItemLocation> get _availableSourceLocations {
    if (_selectedItemId == null) return [];
    final item = context.read<ItemsProvider>().allItems.firstWhere(
      (i) => i.id == _selectedItemId,
      orElse: () => Item(id: '', name: '', locations: []),
    );
    return item.locations.where((loc) => loc.quantity > 0).toList();
  }

  List<Location> get _availableDestinations {
    return context.read<ItemsProvider>().locations
        .where((loc) => loc.id != _selectedFromLocationId)
        .toList();
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
    final isDesktop = MediaQuery.of(context).size.width >= 768;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Transfer Stock'),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
      ),
      body: Consumer3<ItemsProvider, StockTransferProvider, ManagerProvider>(
        builder: (context, itemsProvider, transferProvider, mgrProv, _) {
          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: isDesktop ? 24 : 16, vertical: 16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (transferProvider.errorMessage.isNotEmpty) _buildBanner(
                    transferProvider.errorMessage, Colors.red.shade50, Colors.red.shade200, Colors.red.shade600, Icons.error_outline,
                    onClose: transferProvider.clearError,
                  ),
                  if (transferProvider.successMessage.isNotEmpty) _buildBanner(
                    transferProvider.successMessage, Colors.green.shade50, Colors.green.shade200, Colors.green.shade600, Icons.check_circle,
                    onClose: transferProvider.clearSuccess,
                  ),

                  Card(
                    elevation: 2,
                    shadowColor: Colors.black12,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Transfer Details',
                              style: TextStyle(fontSize: isDesktop ? 20 : 18, fontWeight: FontWeight.bold, color: Colors.grey[800])),
                          const SizedBox(height: 20),

                          // ── Item selection ──
                          _buildItemSelectionSection(itemsProvider),
                          const SizedBox(height: 16),

                          // ── Source location ──
                          if (_selectedItemId != null && _availableSourceLocations.isNotEmpty)
                            _buildSourceLocationDropdown(),
                          if (_selectedItemId != null && _availableSourceLocations.isEmpty)
                            _buildNoStockWarning(),
                          const SizedBox(height: 16),

                          // ── Manager (depends on source location) ──
                          if (_selectedFromLocationId != null)
                            _buildManagerDropdown(mgrProv),
                          if (_selectedFromLocationId != null) const SizedBox(height: 16),

                          // ── Destination location ──
                          if (_selectedFromLocationId != null)
                            _buildDestinationLocationDropdown(),
                          const SizedBox(height: 16),

                          // ── Quantity ──
                          TextFormField(
                            controller: _quantityController,
                            decoration: InputDecoration(
                              labelText: 'Quantity *',
                              prefixIcon: const Icon(Icons.numbers_outlined),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              hintText: 'Enter quantity to transfer',
                            ),
                            keyboardType: TextInputType.number,
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Please enter quantity';
                              final n = int.tryParse(v);
                              if (n == null || n <= 0) return 'Enter a valid quantity greater than 0';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // ── Note ──
                          TextFormField(
                            controller: _noteController,
                            decoration: InputDecoration(
                              labelText: 'Note (Optional)',
                              prefixIcon: const Icon(Icons.note_outlined),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              hintText: 'e.g., Transfer to branch, Restock, etc.',
                            ),
                            maxLines: 3,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: (transferProvider.isLoading || itemsProvider.isLoading || _isScanningBarcode)
                          ? null
                          : _transferStock,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade800,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: (transferProvider.isLoading || itemsProvider.isLoading || _isScanningBarcode)
                          ? const SizedBox(width: 20, height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)))
                          : const Text('Transfer Stock',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBanner(String msg, Color bg, Color border, Color fg, IconData icon, {required VoidCallback onClose}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12), border: Border.all(color: border)),
      child: Row(
        children: [
          Icon(icon, color: fg, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(msg, style: TextStyle(color: fg))),
          IconButton(icon: Icon(Icons.close, color: fg, size: 20), onPressed: onClose),
        ],
      ),
    );
  }

  Widget _buildItemSelectionSection(ItemsProvider itemsProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Barcode card
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
                Row(children: [
                  const Icon(Icons.qr_code_scanner, color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  Text('Scan or Enter Barcode',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey[700])),
                ]),
                const SizedBox(height: 12),
                Stack(children: [
                  TextFormField(
                    controller: _barcodeController,
                    decoration: InputDecoration(
                      labelText: 'Barcode',
                      prefixIcon: const Icon(Icons.qr_code_2_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      hintText: 'Enter barcode or scan',
                      suffixIcon: _barcodeController.text.isNotEmpty
                          ? IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: _clearBarcodeSearch)
                          : null,
                    ),
                    onChanged: (v) { if (v.isEmpty) setState(() => _barcodeSearchError = null); },
                    onFieldSubmitted: (v) { if (v.isNotEmpty) _searchItemByBarcode(v); },
                  ),
                  if (_barcodeController.text.isEmpty)
                    Positioned(
                      right: 8, top: 8,
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
                ]),
                if (_barcodeController.text.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isScanningBarcode ? null : () => _searchItemByBarcode(_barcodeController.text),
                      icon: _isScanningBarcode
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.search, size: 16),
                      label: Text(_isScanningBarcode ? 'Searching...' : 'Search Item'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade600, foregroundColor: Colors.white),
                    ),
                  ),
                ],
                if (_barcodeSearchError != null) ...[
                  const SizedBox(height: 8),
                  _infoBanner(_barcodeSearchError!, Colors.red.shade50, Colors.red.shade200, Colors.red.shade600, Icons.error_outline),
                ],
                if (_selectedItemId != null && _barcodeController.text.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _infoBanner('Item selected via barcode', Colors.green.shade50, Colors.green.shade200, Colors.green.shade600, Icons.check_circle),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: Divider(color: Colors.grey[400])),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text('OR', style: TextStyle(color: Colors.grey[500], fontWeight: FontWeight.w600)),
          ),
          Expanded(child: Divider(color: Colors.grey[400])),
        ]),
        const SizedBox(height: 16),
        _buildItemDropdown(itemsProvider),
      ],
    );
  }

  Widget _infoBanner(String msg, Color bg, Color border, Color fg, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8), border: Border.all(color: border)),
      child: Row(children: [
        Icon(icon, color: fg, size: 16),
        const SizedBox(width: 8),
        Expanded(child: Text(msg, style: TextStyle(color: fg, fontSize: 12))),
      ]),
    );
  }

  Widget _buildItemDropdown(ItemsProvider itemsProvider) {
    return DropdownButtonFormField<String>(
      value: _selectedItemId,
      decoration: InputDecoration(
        labelText: 'Select Item *',
        prefixIcon: const Icon(Icons.list_alt_outlined),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      items: itemsProvider.allItems.map((item) => DropdownMenuItem<String>(
        value: item.id,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${item.name}${item.modelNumber?.isNotEmpty == true ? " (${item.modelNumber})" : ""}',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            Text('SKU: ${item.sku ?? "N/A"}  ·  Stock: ${item.totalStock ?? 0} ${item.unit ?? ""}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ],
        ),
      )).toList(),
      onChanged: (v) {
        setState(() {
          _selectedItemId = v;
          _selectedFromLocationId = null;
          _selectedToLocationId = null;
          _selectedManagerId = null;
          _barcodeController.clear();
          _barcodeSearchError = null;
        });
      },
      validator: (v) => v == null ? 'Please select an item' : null,
    );
  }

  Widget _buildSourceLocationDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedFromLocationId,
      decoration: InputDecoration(
        labelText: 'From Location *',
        prefixIcon: const Icon(Icons.output_outlined),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      items: _availableSourceLocations.map((loc) => DropdownMenuItem<String>(
        value: loc.locationId,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(loc.name, style: const TextStyle(fontWeight: FontWeight.w500)),
            Text('Available: ${loc.quantity}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ],
        ),
      )).toList(),
      onChanged: _onFromLocationChanged,
      validator: (v) => v == null ? 'Please select source location' : null,
    );
  }

  Widget _buildManagerDropdown(ManagerProvider mgrProv) {
    final managers = mgrProv.locationManagers.where((m) => m.isActive).toList();
    return DropdownButtonFormField<String>(
      value: _selectedManagerId,
      decoration: InputDecoration(
        labelText: 'Manager (Optional)',
        prefixIcon: const Icon(Icons.manage_accounts_outlined),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        hintText: managers.isEmpty ? 'No managers for this location' : null,
      ),
      items: [
        const DropdownMenuItem<String>(value: null, child: Text('No manager')),
        ...managers.map((m) => DropdownMenuItem<String>(value: m.id, child: Text(m.name))),
      ],
      onChanged: managers.isEmpty ? null : (v) => setState(() => _selectedManagerId = v),
    );
  }

  Widget _buildDestinationLocationDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedToLocationId,
      decoration: InputDecoration(
        labelText: 'To Location *',
        prefixIcon: const Icon(Icons.input_outlined),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      items: _availableDestinations.map((loc) => DropdownMenuItem<String>(
        value: loc.id,
        child: Text(loc.name),
      )).toList(),
      onChanged: (v) => setState(() => _selectedToLocationId = v),
      validator: (v) => v == null ? 'Please select destination location' : null,
    );
  }

  Widget _buildNoStockWarning() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(children: [
        Icon(Icons.warning, color: Colors.orange.shade600, size: 20),
        const SizedBox(width: 8),
        Expanded(child: Text('Selected item has no available stock in any location',
            style: TextStyle(color: Colors.orange.shade600))),
      ]),
    );
  }
}
