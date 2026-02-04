import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stock_buddy/providers/stock_provider.dart';
import 'package:stock_buddy/models/location_model.dart';

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

                      return Card(
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