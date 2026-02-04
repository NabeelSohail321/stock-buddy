import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../providers/items_provider.dart';
import '../../models/item_model.dart';

class ItemsScreen extends StatefulWidget {
  const ItemsScreen({super.key});

  @override
  State<ItemsScreen> createState() => _ItemsScreenState();
}

class _ItemsScreenState extends State<ItemsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isScanning = false;
  MobileScannerController? _cameraController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadItems();
    });
  }

  void _loadItems() {
    final itemsProvider = context.read<ItemsProvider>();
    itemsProvider.fetchItems();
  }

  void _onSearchChanged(String query) {
    final itemsProvider = context.read<ItemsProvider>();
    itemsProvider.searchItems(query);
  }

  void _clearSearch() {
    _searchController.clear();
    _onSearchChanged('');
    _searchFocusNode.unfocus();
  }

  Future<void> _startBarcodeScan() async {
    // Check camera permission
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Camera permission is required to scan barcodes'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isScanning = true;
    });

    // Initialize camera controller
    _cameraController = MobileScannerController(
      facing: CameraFacing.back,
      formats: [BarcodeFormat.all],
      returnImage: false,
    );
  }

  void _stopBarcodeScan() {
    setState(() {
      _isScanning = false;
    });
    _cameraController?.dispose();
    _cameraController = null;
  }

  void _onBarcodeDetected(BarcodeCapture barcodes) {
    final List<Barcode> barcodeList = barcodes.barcodes;

    if (barcodeList.isNotEmpty) {
      final String barcodeValue = barcodeList.first.rawValue ?? '';

      if (barcodeValue.isNotEmpty) {
        // Set the scanned barcode in search field
        _searchController.text = barcodeValue;
        _onSearchChanged(barcodeValue);

        // Stop scanning after successful detection
        _stopBarcodeScan();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Scanned barcode: $barcodeValue'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Items'),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
        actions: [
          if (isMobile && !_isScanning)
            IconButton(
              icon: const Icon(Icons.qr_code_scanner),
              onPressed: _startBarcodeScan,
              tooltip: 'Scan Barcode',
            ),
        ],
      ),
      body: _isScanning ? _buildScannerView() : _buildItemsView(),
      floatingActionButton: _isScanning ? null : FloatingActionButton(
        onPressed: _loadItems,
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
        child: const Icon(Icons.refresh),
      ),
    );
  }

  Widget _buildScannerView() {
    return Stack(
      children: [
        MobileScanner(
          controller: _cameraController,
          onDetect: _onBarcodeDetected,
        ),
        Positioned(
          top: 40,
          left: 20,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Scanning Barcode...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        Positioned(
          top: 40,
          right: 20,
          child: IconButton(
            icon: const Icon(Icons.close, color: Colors.white, size: 30),
            onPressed: _stopBarcodeScan,
          ),
        ),
        Positioned(
          bottom: 100,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.all(16),
            child: const Text(
              'Point camera at barcode to scan',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        // Scanner overlay
        Positioned(
          top: MediaQuery.of(context).size.height * 0.3,
          left: MediaQuery.of(context).size.width * 0.2,
          right: MediaQuery.of(context).size.width * 0.2,
          child: Container(
            height: 200,
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.green,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: CustomPaint(
              painter: ScannerOverlayPainter(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildItemsView() {
    return Consumer<ItemsProvider>(
      builder: (context, itemsProvider, child) {
        return Column(
          children: [
            // Search Bar
            _buildSearchBar(itemsProvider),

            // Error Message
            if (itemsProvider.errorMessage.isNotEmpty)
              _buildErrorWidget(itemsProvider),

            // Loading Indicator
            if (itemsProvider.isLoading)
              _buildLoadingWidget(),

            // Content
            if (!itemsProvider.isLoading)
              _buildContent(itemsProvider),
          ],
        );
      },
    );
  }

  Widget _buildSearchBar(ItemsProvider itemsProvider) {
    final bool isMobile = MediaQuery.of(context).size.width < 768;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Search items by name, SKU, or barcode...',
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (itemsProvider.searchQuery.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey),
                          onPressed: _clearSearch,
                        ),
                      if (isMobile)
                        IconButton(
                          icon: const Icon(Icons.qr_code_scanner, color: Colors.blue),
                          onPressed: _startBarcodeScan,
                          tooltip: 'Scan Barcode',
                        ),
                    ],
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(ItemsProvider itemsProvider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade600, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Failed to load items',
                  style: TextStyle(
                    color: Colors.red.shade600,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  itemsProvider.errorMessage,
                  style: TextStyle(color: Colors.red.shade600),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, color: Colors.red.shade600),
            onPressed: () => itemsProvider.clearError(),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return const Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Loading items...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(ItemsProvider itemsProvider) {
    if (itemsProvider.items.isEmpty) {
      return _buildEmptyState(itemsProvider);
    } else {
      return _buildItemsList(itemsProvider);
    }
  }

  Widget _buildEmptyState(ItemsProvider itemsProvider) {
    final bool isMobile = MediaQuery.of(context).size.width < 768;

    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              itemsProvider.searchQuery.isNotEmpty
                  ? 'No items found for "${itemsProvider.searchQuery}"'
                  : 'No items available',
              style: const TextStyle(
                fontSize: 18,
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              itemsProvider.searchQuery.isNotEmpty
                  ? 'Try adjusting your search terms'
                  : 'Items will appear here once added to the system',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            if (itemsProvider.searchQuery.isNotEmpty) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _clearSearch,
                child: const Text('Clear Search'),
              ),
            ],
            if (isMobile && itemsProvider.searchQuery.isEmpty) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _startBarcodeScan,
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('Scan Barcode to Search'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade800,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildItemsList(ItemsProvider itemsProvider) {
    return Expanded(
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: itemsProvider.items.length,
        separatorBuilder: (context, index) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final item = itemsProvider.items[index];
          return _buildItemCard(item);
        },
      ),
    );
  }

  Widget _buildItemCard(Item item) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'SKU: ${item.sku}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      if (item.barcode != null && item.barcode!.isNotEmpty)
                        Text(
                          'Barcode: ${item.barcode}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Stock Status Badge
                // Container(
                //   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                //   decoration: BoxDecoration(
                //     color: item.stockStatusColor.withOpacity(0.1),
                //     borderRadius: BorderRadius.circular(20),
                //     border: Border.all(color: item.stockStatusColor),
                //   ),
                //   child: Text(
                //     item.stockStatusDisplay,
                //     style: TextStyle(
                //       color: item.stockStatusColor,
                //       fontSize: 12,
                //       fontWeight: FontWeight.bold,
                //     ),
                //   ),
                // ),
              ],
            ),
            const SizedBox(height: 12),

            // Stock Information
            Row(
              children: [
                _buildInfoChip(
                  icon: Icons.inventory_2,
                  label: '${item.totalStock} ${item.unit}',
                  color: Colors.blue,
                ),
                const SizedBox(width: 8),
                _buildInfoChip(
                  icon: Icons.warning,
                  label: 'Threshold: ${item.threshold}',
                  color: Colors.orange,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Locations
            if (item.locations.isNotEmpty) ...[
              Text(
                'Locations:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: item.locations.map((location) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Text(
                      '${location.name}: ${location.quantity}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// Custom painter for scanner overlay
class ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.green
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(0, 20)
      ..lineTo(0, 0)
      ..lineTo(20, 0)
      ..moveTo(size.width - 20, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, 20)
      ..moveTo(size.width, size.height - 20)
      ..lineTo(size.width, size.height)
      ..lineTo(size.width - 20, size.height)
      ..moveTo(20, size.height)
      ..lineTo(0, size.height)
      ..lineTo(0, size.height - 20);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}