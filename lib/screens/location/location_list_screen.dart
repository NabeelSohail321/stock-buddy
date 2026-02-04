import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stock_buddy/models/location_model.dart';
import 'package:stock_buddy/providers/auth_provider.dart';
import 'package:stock_buddy/providers/location_provider.dart';
import 'package:stock_buddy/screens/location/add_edit_location_screen.dart';

class LocationListScreen extends StatefulWidget {
  const LocationListScreen({super.key});

  @override
  State<LocationListScreen> createState() => _LocationListScreenState();
}

class _LocationListScreenState extends State<LocationListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadLocations();
    });
  }

  Future<void> _loadLocations() async {
    final locationProvider = context.read<LocationProvider>();
    final authProvider = context.read<AuthProvider>();

    // Only load locations if user is authenticated
    if (authProvider.token != null && authProvider.token!.isNotEmpty) {
      await locationProvider.loadLocations();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    // Check if user is authenticated and has admin role
    final isAuthenticated = authProvider.token != null && authProvider.token!.isNotEmpty;
    final isAdmin = authProvider.currentUser?.role == 'admin';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Locations'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        actions: [
          if (isAuthenticated && isAdmin)
            IconButton(
              icon: const Icon(Icons.add, size: 24),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddEditLocationScreen(),
                  ),
                );
              },
            ),
        ],
      ),
      body: _buildBody(isAuthenticated, isAdmin),
    );
  }

  Widget _buildBody(bool isAuthenticated, bool isAdmin) {
    final locationProvider = context.watch<LocationProvider>();

    // Show loading state only if authenticated
    if (!isAuthenticated) {
      return _buildNotAuthenticated();
    }

    if (locationProvider.isLoading && locationProvider.locations.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Loading locations...',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (locationProvider.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Error loading locations',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Text(
                locationProvider.error!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => locationProvider.loadLocations(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    if (locationProvider.locations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.location_on_outlined, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No Locations Found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32.0),
              child: Text(
                'Get started by adding your first location to manage your inventory',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 24),
            if (isAdmin)
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddEditLocationScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.add, size: 20),
                label: const Text('Add First Location'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              )
            else
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 32.0),
                child: Text(
                  'Contact your administrator to add new locations',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Info banner for non-admin users
        if (!isAdmin)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              border: Border.all(color: Colors.blue[100]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info, color: Colors.blue[600], size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Viewing all locations. Contact administrator for modifications.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.blue[800],
                    ),
                  ),
                ),
              ],
            ),
          ),

        // Location count
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Text(
                '${locationProvider.locations.length} location${locationProvider.locations.length != 1 ? 's' : ''} found',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
              const Spacer(),
              if (locationProvider.isLoading)
                const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
        ),

        // Locations list
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => locationProvider.loadLocations(),
            child: ListView.separated(
              itemCount: locationProvider.locations.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final location = locationProvider.locations[index];
                return _buildLocationCard(location, locationProvider, isAdmin);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNotAuthenticated() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.warning_amber, size: 80, color: Colors.orange),
          const SizedBox(height: 16),
          const Text(
            'Authentication Required',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.orange,
            ),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              'Please log in to view and manage locations',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              // This will trigger the AuthWrapper to show login screen
              context.read<AuthProvider>().logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Go to Login'),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard(Location location, LocationProvider locationProvider, bool isAdmin) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: location.isActive ? Colors.blue : Colors.grey,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.location_on,
              color: Colors.white,
              size: 24,
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  location.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    decoration: location.isActive ? null : TextDecoration.lineThrough,
                    color: location.isActive ? Colors.black : Colors.grey,
                  ),
                ),
              ),
              if (!location.isActive)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.grey),
                  ),
                  child: Text(
                    'INACTIVE',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (location.address != null && location.address!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0, bottom: 6.0),
                  child: Text(
                    location.address!,
                    style: TextStyle(
                      fontSize: 14,
                      color: location.isActive ? Colors.black54 : Colors.grey,
                    ),
                  ),
                ),
              if (location.createdByName != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: Text(
                    'Created by: ${location.createdByName!}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
              if (location.isActive)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.green),
                  ),
                  child: Text(
                    'ACTIVE',
                    style: TextStyle(
                      color: Colors.green[700],
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          trailing: isAdmin
              ? PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.grey),
            onSelected: (value) => _handlePopupMenuSelected(
              value,
              location,
              locationProvider,
            ),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 20, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('Edit'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: location.isActive ? 'deactivate' : 'activate',
                child: Row(
                  children: [
                    Icon(
                      location.isActive ? Icons.toggle_off : Icons.toggle_on,
                      size: 20,
                      color: location.isActive ? Colors.orange : Colors.green,
                    ),
                    const SizedBox(width: 8),
                    Text(location.isActive ? 'Deactivate' : 'Activate'),
                  ],
                ),
              ),
            ],
          )
              : null,
        ),
      ),
    );
  }

  void _handlePopupMenuSelected(
      String value,
      Location location,
      LocationProvider locationProvider,
      ) {
    switch (value) {
      case 'edit':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AddEditLocationScreen(location: location),
          ),
        );
        break;
      case 'activate':
      case 'deactivate':
        _toggleLocationStatus(location, locationProvider);
        break;
    }
  }

  void _toggleLocationStatus(Location location, LocationProvider locationProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          location.isActive ? 'Deactivate Location' : 'Activate Location',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          location.isActive
              ? 'Are you sure you want to deactivate "${location.name}"? This location will no longer be available for new stock operations.'
              : 'Are you sure you want to activate "${location.name}"? This location will be available for stock operations.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              locationProvider.updateLocation(
                id: location.id,
                name: location.name,
                address: location.address ?? '',
                isActive: !location.isActive,
              );

              // Show success message
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    location.isActive
                        ? 'Location "${location.name}" deactivated'
                        : 'Location "${location.name}" activated',
                  ),
                  backgroundColor: location.isActive ? Colors.orange : Colors.green,
                ),
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: location.isActive ? Colors.orange : Colors.green,
            ),
            child: Text(location.isActive ? 'Deactivate' : 'Activate'),
          ),
        ],
      ),
    );
  }
}