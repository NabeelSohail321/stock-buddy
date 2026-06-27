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
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showItemDetailSheet(item),
        child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row: icon + name + status badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: item.statusColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: item.statusColor),
                  ),
                  child: Icon(_getStatusIcon(item.stockStatus), color: item.statusColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      if (item.modelNumber != null && item.modelNumber!.isNotEmpty)
                        Text('Model: ${item.modelNumber}',
                            style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: item.statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: item.statusColor),
                  ),
                  child: Text(item.stockStatus.toUpperCase(),
                      style: TextStyle(color: item.statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 10),

            // Details grid
            Row(
              children: [
                _buildInfoChip(Icons.qr_code_outlined, 'Barcode',
                    item.barcode?.isNotEmpty == true ? item.barcode! : 'N/A'),
                const SizedBox(width: 12),
                _buildInfoChip(Icons.straighten_outlined, 'Unit', item.unit ?? 'N/A'),
              ],
            ),
            const SizedBox(height: 8),

            // Location breakdown
            if (item.locations.isNotEmpty) ...[
              Text('Stock by Location:',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[700])),
              const SizedBox(height: 4),
              ...item.locations.map((loc) {
                final locName = loc['locationId'] is Map
                    ? loc['locationId']['name'] ?? 'Unknown'
                    : 'Location';
                final qty = loc['quantity'] ?? 0;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(children: [
                    Icon(Icons.location_on_outlined, size: 13, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Expanded(child: Text(locName, style: TextStyle(fontSize: 12, color: Colors.grey[700]))),
                    Text('$qty ${item.unit ?? ""}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: qty <= 0 ? Colors.red : Colors.grey[800],
                        )),
                  ]),
                );
              }),
              const SizedBox(height: 8),
            ],

            // Stock progress bar
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: item.threshold > 0 ? (item.currentStock / item.threshold).clamp(0.0, 1.0) : 0,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(item.statusColor),
                    minHeight: 7,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${item.currentStock} / ${item.threshold}',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: item.statusColor),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${item.stockDeficit} ${item.unit ?? "units"} below threshold',
              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text('Tap for details',
                    style: TextStyle(fontSize: 11, color: Colors.blue[400])),
                const SizedBox(width: 2),
                Icon(Icons.chevron_right, size: 14, color: Colors.blue[400]),
              ],
            ),
          ],
        ),
        ),
      ),
    );
  }

  void _showItemDetailSheet(LowStockItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollController) => _LowStockDetailSheet(
          item: item,
          scrollController: scrollController,
          getStatusIcon: _getStatusIcon,
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: Colors.grey[500]),
        const SizedBox(width: 3),
        Text('$label: ', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
      ],
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

// ─── Detail bottom sheet ────────────────────────────────────────────────────

class _LowStockDetailSheet extends StatelessWidget {
  final LowStockItem item;
  final ScrollController scrollController;
  final IconData Function(String) getStatusIcon;

  const _LowStockDetailSheet({
    required this.item,
    required this.scrollController,
    required this.getStatusIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 6),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(4),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: item.statusColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(color: item.statusColor, width: 1.5),
                  ),
                  child: Icon(getStatusIcon(item.stockStatus),
                      color: item.statusColor, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.name,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      if (item.modelNumber?.isNotEmpty == true)
                        Text(item.modelNumber!,
                            style: TextStyle(
                                fontSize: 13, color: Colors.grey[600])),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: item.statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: item.statusColor),
                  ),
                  child: Text(item.stockStatus.toUpperCase(),
                      style: TextStyle(
                          color: item.statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Scrollable details
          Expanded(
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.all(20),
              children: [
                // Identity section
                _sectionTitle('Item Information'),
                _detailRow(Icons.qr_code_outlined, 'Barcode',
                    item.barcode?.isNotEmpty == true ? item.barcode! : '—'),
                _detailRow(Icons.straighten_outlined, 'Unit', item.unit ?? '—'),
                if (item.sku.isNotEmpty) _detailRow(Icons.tag_outlined, 'SKU', item.sku),
                if (item.serialNumber?.isNotEmpty == true)
                  _detailRow(Icons.fingerprint_outlined, 'Serial Number',
                      item.serialNumber!),
                const SizedBox(height: 16),

                // Stock section
                _sectionTitle('Stock Status'),
                _detailRow(Icons.inventory_2_outlined, 'Current Stock',
                    '${item.currentStock} ${item.unit ?? ""}'),
                _detailRow(Icons.warning_amber_outlined, 'Threshold',
                    '${item.threshold} ${item.unit ?? ""}'),
                _detailRow(Icons.trending_down_outlined, 'Deficit',
                    '${item.stockDeficit} ${item.unit ?? "units"} below threshold',
                    valueColor: Colors.red),

                // Progress bar
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: item.threshold > 0
                        ? (item.currentStock / item.threshold).clamp(0.0, 1.0)
                        : 0,
                    backgroundColor: Colors.grey[200],
                    valueColor:
                        AlwaysStoppedAnimation<Color>(item.statusColor),
                    minHeight: 10,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${((item.currentStock / item.threshold) * 100).clamp(0, 100).toStringAsFixed(0)}% of threshold remaining',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
                const SizedBox(height: 16),

                // Locations section
                if (item.locations.isNotEmpty) ...[
                  _sectionTitle('Stock by Location'),
                  ...item.locations.map((loc) {
                    final locName = loc['locationId'] is Map
                        ? (loc['locationId']['name'] ?? 'Unknown Location')
                        : 'Location';
                    final locId = loc['locationId'] is Map
                        ? (loc['locationId']['_id'] ?? '')
                        : '';
                    final qty = loc['quantity'] ?? 0;
                    final managerName = loc['managerId'] is Map
                        ? loc['managerId']['name']
                        : null;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      color: Colors.grey[50],
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: Colors.grey[200]!),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.location_on,
                                    size: 16, color: Colors.blue[600]),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(locName,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13)),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: qty <= 0
                                        ? Colors.red[50]
                                        : Colors.green[50],
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: qty <= 0
                                            ? Colors.red
                                            : Colors.green),
                                  ),
                                  child: Text(
                                    '$qty ${item.unit ?? ""}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: qty <= 0 ? Colors.red : Colors.green,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (managerName != null) ...[
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(Icons.manage_accounts_outlined,
                                      size: 14, color: Colors.teal[600]),
                                  const SizedBox(width: 6),
                                  Text('Manager: ',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600])),
                                  Text(managerName,
                                      style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500)),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }),
                ] else ...[
                  _sectionTitle('Stock by Location'),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text('No location data available',
                        style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
            fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value,
      {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey[500]),
          const SizedBox(width: 8),
          SizedBox(
            width: 120,
            child: Text(label,
                style: TextStyle(fontSize: 13, color: Colors.grey[600])),
          ),
          Expanded(
            child: Text(value,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: valueColor ?? Colors.black87)),
          ),
        ],
      ),
    );
  }
}