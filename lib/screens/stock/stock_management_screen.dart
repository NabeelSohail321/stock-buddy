import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stock_buddy/providers/items_provider.dart';
import 'package:stock_buddy/providers/stock_provider.dart';
import 'package:stock_buddy/models/location_model.dart';
import 'package:stock_buddy/screens/stock/add_stock_screen.dart';
import 'package:stock_buddy/screens/stock/stock_by_location_screen.dart';

class StockManagementScreen extends StatefulWidget {
  const StockManagementScreen({Key? key}) : super(key: key);

  @override
  State<StockManagementScreen> createState() => _StockManagementScreenState();
}

class _StockManagementScreenState extends State<StockManagementScreen> {
  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final itemsProvider = Provider.of<ItemsProvider>(context, listen: false);
      if (itemsProvider.locations.isEmpty) {
        itemsProvider.fetchLocations();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width >= 768;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock Management'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Consumer<ItemsProvider>(
        builder: (context, itemsProvider, child) {
          if (itemsProvider.locationsLoading && itemsProvider.locations.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (itemsProvider.locationsErrorMessage.isNotEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Error: ${itemsProvider.locationsErrorMessage}',
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      itemsProvider.fetchLocations();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 24 : 16,
              vertical: 16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Text(
                  'Stock Management',
                  style: TextStyle(
                    fontSize: isDesktop ? 28 : 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Manage your inventory stock levels',
                  style: TextStyle(
                    fontSize: isDesktop ? 16 : 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 32),

                // Quick Actions Grid
                _buildQuickActionsGrid(isDesktop),
                const SizedBox(height: 32),

                // Locations Section
                _buildLocationsSection(itemsProvider, isDesktop),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuickActionsGrid(bool isDesktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: isDesktop ? 20 : 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: isDesktop ? 2 : 1,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 3.0,
          children: [
            _buildQuickActionCard(
              icon: Icons.add_box_rounded,
              title: 'Add Stock',
              subtitle: 'Receive stock into a location',
              color: Colors.green.shade700,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddStockScreen(),
                  ),
                );
              },
            ),
            // _buildQuickActionCard(
            //   icon: Icons.analytics_rounded,
            //   title: 'Stock Overview',
            //   subtitle: 'View all stock across locations',
            //   color: Colors.blue.shade700,
            //   onTap: () {
            //     // This could navigate to an overview screen showing all stock
            //     ScaffoldMessenger.of(context).showSnackBar(
            //       const SnackBar(
            //         content: Text('Stock Overview feature coming soon!'),
            //       ),
            //     );
            //   },
            // ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: color,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationsSection(ItemsProvider itemsProvider, bool isDesktop) {
    final locations = itemsProvider.locations;

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Stock by Location',
                style: TextStyle(
                  fontSize: isDesktop ? 20 : 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  itemsProvider.fetchLocations();
                },
                tooltip: 'Refresh Locations',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Select a location to view its stock',
            style: TextStyle(
              fontSize: isDesktop ? 14 : 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),

          if (locations.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.location_off_rounded, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text(
                      'No locations available',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Add locations to manage stock',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: locations.length,
                itemBuilder: (context, index) {
                  final location = locations[index];
                  return _buildLocationCard(location);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLocationCard(Location location) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.warehouse_rounded, color: Colors.blue),
        ),
        title: Text(
          location.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: location.address != null
            ? Text(
          location.address!,
          style: const TextStyle(fontSize: 12),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        )
            : null,
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => StockByLocationScreen(location: location),
            ),
          );
        },
      ),
    );
  }
}