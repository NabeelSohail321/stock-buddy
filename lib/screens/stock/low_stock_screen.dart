import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stock_buddy/models/dashboard_model.dart';
import 'package:stock_buddy/providers/items_provider.dart';

class LowStockScreen extends StatefulWidget {
  const LowStockScreen({super.key});

  @override
  State<LowStockScreen> createState() => _LowStockScreenState();
}

class _LowStockScreenState extends State<LowStockScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDashboardData();
    });
  }

  Future<void> _loadDashboardData() async {
    final itemsProvider = context.read<ItemsProvider>();
    await itemsProvider.fetchDashboardData();
  }

  @override
  Widget build(BuildContext context) {
    final itemsProvider = context.watch<ItemsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Low Stock Items'),
        backgroundColor: Colors.orange[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _buildBody(itemsProvider),
    );
  }

  Widget _buildBody(ItemsProvider itemsProvider) {
    if (itemsProvider.dashboardLoading && itemsProvider.dashboardData == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading low stock items...'),
          ],
        ),
      );
    }

    if (itemsProvider.dashboardErrorMessage.isNotEmpty && itemsProvider.dashboardData == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Error loading data',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Text(
                itemsProvider.dashboardErrorMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadDashboardData,
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    final dashboardData = itemsProvider.dashboardData;
    if (dashboardData == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No data available',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Summary Cards
        _buildSummarySection(dashboardData.summary),

        // Low Stock Items List
        Expanded(
          child: _buildLowStockList(dashboardData.lowStockItems),
        ),
      ],
    );
  }

  Widget _buildSummarySection(DashboardSummary summary) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Text(
            'Stock Overview',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Total Items
              Expanded(
                child: _buildSummaryCard(
                  icon: Icons.inventory_2,
                  title: 'Total Items',
                  value: summary.totalItems.toString(),
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              // Total Stock
              Expanded(
                child: _buildSummaryCard(
                  icon: Icons.warehouse,
                  title: 'Total Stock',
                  value: summary.totalStock.toString(),
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Low Stock Items
              Expanded(
                child: _buildSummaryCard(
                  icon: Icons.warning_amber,
                  title: 'Low Stock',
                  value: summary.lowStockCount.toString(),
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              // Pending Actions
              Expanded(
                child: _buildSummaryCard(
                  icon: Icons.pending_actions,
                  title: 'Pending Actions',
                  value: (summary.pendingRepairs + summary.pendingDisposals).toString(),
                  color: Colors.purple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLowStockList(List<LowStockItem> lowStockItems) {
    if (lowStockItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
            const SizedBox(height: 16),
            const Text(
              'All items are well stocked!',
              style: TextStyle(fontSize: 18, color: Colors.green),
            ),
            const SizedBox(height: 8),
            Text(
              'No items are below their threshold levels',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Text(
                '${lowStockItems.length} item${lowStockItems.length != 1 ? 's' : ''} below threshold',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Text(
                  'ACTION NEEDED',
                  style: TextStyle(
                    color: Colors.orange[700],
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Items List
        Expanded(
          child: ListView.builder(
            itemCount: lowStockItems.length,
            itemBuilder: (context, index) {
              final item = lowStockItems[index];
              return _buildLowStockItemCard(item);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLowStockItemCard(LowStockItem item) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: item.statusColor.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: item.statusColor),
          ),
          child: Icon(
            _getStatusIcon(item.stockStatus),
            color: item.statusColor,
            size: 24,
          ),
        ),
        title: Text(
          item.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('SKU: ${item.sku}'),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: item.stockPercentage / 100,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(item.statusColor),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${item.currentStock}/${item.threshold}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: item.statusColor,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: item.statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: item.statusColor),
          ),
          child: Text(
            item.stockStatus.toUpperCase(),
            style: TextStyle(
              color: item.statusColor,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Out of Stock':
        return Icons.error_outline;
      case 'Critical':
        return Icons.warning_amber;
      case 'Low':
        return Icons.info_outline;
      default:
        return Icons.inventory_2;
    }
  }
}