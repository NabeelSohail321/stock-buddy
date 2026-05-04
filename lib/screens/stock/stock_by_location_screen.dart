import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stock_buddy/providers/stock_provider.dart';
import 'package:stock_buddy/models/location_model.dart';
import 'package:intl/intl.dart';
import 'package:stock_buddy/models/item_model.dart';

class StockByLocationScreen extends StatefulWidget {
  final Location location;

  const StockByLocationScreen({Key? key, required this.location}) : super(key: key);

  @override
  State<StockByLocationScreen> createState() => _StockByLocationScreenState();
}

class _StockByLocationScreenState extends State<StockByLocationScreen> {
  @override
  void initState() {
    super.initState();
    _loadStockData();
  }

  void _loadStockData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<StockProvider>(context, listen: false)
          .getStockByLocation(widget.location.id);
    });
  }

  MaterialColor _getStockStatusColor(String status) {
    switch (status) {
      case 'sufficient':
        return Colors.green;
      case 'low':
        return Colors.orange;
      case 'critical':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStockStatusText(String status) {
    switch (status) {
      case 'sufficient':
        return 'Sufficient';
      case 'low':
        return 'Low Stock';
      case 'critical':
        return 'Critical';
      default:
        return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Stock - ${widget.location.name}'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStockData,
          ),
        ],
      ),
      body: Consumer<StockProvider>(
        builder: (context, stockProvider, child) {
          if (stockProvider.isLoading && stockProvider.locationStock.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (stockProvider.error.isNotEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Error: ${stockProvider.error}',
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _loadStockData,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (stockProvider.locationStock.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'No stock available',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No items found in ${widget.location.name}',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Location Info
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Icon(Icons.warehouse_rounded, color: Colors.blue, size: 40),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.location.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (widget.location.address != null)
                                Text(
                                  widget.location.address!,
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 14,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Stock Summary
                Text(
                  'Stock Items (${stockProvider.locationStock.length})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // Stock List
                Expanded(
                  child: ListView.builder(
                    itemCount: stockProvider.locationStock.length,
                    itemBuilder: (context, index) {
                      final stockItem = stockProvider.locationStock[index];
                      final item = stockItem['item'];
                      final quantity = stockItem['quantity'] ?? 0;
                      final status = stockItem['status'] ?? 'unknown';

                      final itemName = item['name'] ?? 'Unknown Item';
                      final sku = item['sku'] ?? 'No SKU';
                      final unit = item['unit'] ?? 'units';
                      final threshold = item['threshold'] ?? 0;
                      final modelNumber = (item['modelNumber'] ?? item['model_number'])?.toString();
                      final serialNumber = (item['serialNumber'] ?? item['serial_number'])?.toString();
                      final barcode = item['barcode']?.toString();

                      return InkWell(
                        onTap: () => _showItemDetailSheet(context, stockItem),
                        borderRadius: BorderRadius.circular(12),
                        child: Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header row
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            itemName,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            'SKU: $sku',
                                            style: const TextStyle(
                                              color: Colors.grey,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: _getStockStatusColor(status).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: _getStockStatusColor(status),
                                        ),
                                      ),
                                      child: Text(
                                        _getStockStatusText(status),
                                        style: TextStyle(
                                          color: _getStockStatusColor(status),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
      
                                // Stock details
                                if (modelNumber != null && modelNumber.isNotEmpty)
                                  _buildStockDetailRow('Model:', modelNumber),
                                if (serialNumber != null && serialNumber.isNotEmpty)
                                  _buildStockDetailRow('Serial:', serialNumber),
                                if (barcode != null && barcode.isNotEmpty)
                                  _buildStockDetailRow('Barcode:', barcode),
                                _buildStockDetailRow('Quantity:', '$quantity $unit'),
                                _buildStockDetailRow('Threshold:', '$threshold $unit'),
                                _buildStockDetailRow('Status:', _getStockStatusText(status).toUpperCase()),
      
                                // Progress bar for visual indication
                                const SizedBox(height: 8),
                                LinearProgressIndicator(
                                  value: threshold > 0 ? quantity / (threshold * 2) : 0.5,
                                  backgroundColor: Colors.grey.shade200,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    _getStockStatusColor(status),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showItemDetailSheet(BuildContext context, Map<String, dynamic> stockData) {
    final itemData = stockData['item'];
    final item = Item.fromJson(itemData);
    final currentQuantity = stockData['quantity'] ?? 0;
    final status = stockData['status'] ?? 'unknown';
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  
                  // Header
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: item.hasImage
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  item.image!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(Icons.inventory_2, color: Colors.blue, size: 40),
                                ),
                              )
                            : const Icon(Icons.inventory_2, color: Colors.blue, size: 40),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'SKU: ${item.sku ?? "N/A"}',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getStockStatusColor(status).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _getStockStatusText(status).toUpperCase(),
                                style: TextStyle(
                                  color: _getStockStatusColor(status),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const Divider(height: 40),
                  
                  // Identification Section
                  _buildSectionTitle('Identification'),
                  _buildDetailRow(Icons.tag, 'Barcode', item.barcode ?? 'N/A'),
                  _buildDetailRow(Icons.model_training, 'Model No', item.modelNumber ?? 'N/A'),
                  _buildDetailRow(Icons.numbers, 'Serial No', item.serialNumber ?? 'N/A'),
                  
                  const SizedBox(height: 24),
                  
                  // Inventory Section
                  _buildSectionTitle('Inventory Status'),
                  _buildDetailRow(
                    Icons.location_on, 
                    'At this Location', 
                    '$currentQuantity ${item.unit ?? "units"}'
                  ),
                  _buildDetailRow(
                    Icons.inventory, 
                    'Total Stock', 
                    '${item.totalStock ?? currentQuantity} ${item.unit ?? "units"}'
                  ),
                  _buildDetailRow(
                    Icons.warning_amber_rounded, 
                    'Threshold', 
                    '${item.threshold ?? 0} ${item.unit ?? "units"}'
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Metadata Section
                  _buildSectionTitle('Information'),
                  _buildDetailRow(
                    Icons.calendar_today, 
                    'Purchase Date', 
                    item.purchaseDate != null 
                        ? DateFormat('MMM dd, yyyy').format(item.purchaseDate!) 
                        : 'N/A'
                  ),
                  _buildDetailRow(
                    Icons.history, 
                    'Created At', 
                    item.createdAt != null 
                        ? DateFormat('MMM dd, yyyy HH:mm').format(item.createdAt!) 
                        : 'N/A'
                  ),
                  _buildDetailRow(
                    Icons.edit_note, 
                    'Last Updated', 
                    item.updatedAt != null 
                        ? DateFormat('MMM dd, yyyy HH:mm').format(item.updatedAt!) 
                        : 'N/A'
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Action button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Close Details'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.blue,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Text(
            '$label:',
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStockDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}