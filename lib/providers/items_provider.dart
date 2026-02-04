import 'package:flutter/foundation.dart';

import '../models/dashboard_model.dart';
import '../models/item_model.dart';
import '../models/location_model.dart';
import '../models/stock_model.dart';
import '../services/item_service.dart';

class ItemsProvider with ChangeNotifier {
  final ItemsService _itemsService;

  ItemsProvider({required ItemsService itemsService})
      : _itemsService = itemsService;

  bool _isLoading = false;
  String _searchQuery = '';
  String _errorMessage = '';
  final List<Item> _items = [];
  List<Item> _filteredItems = [];
  List<Item> get items => _filteredItems;
  List<Item> get allItems => _items;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;

  // Update the createItem method in ItemsProvider
  Future<bool> createItem({
    required String name,
    required String sku,
    required String barcode,
    required String unit,
    required int threshold,
    required List<String> locations,
    String? image, // Add optional image parameter
  }) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final newItem = await _itemsService.createItem(
        name: name,
        sku: sku,
        barcode: barcode,
        unit: unit,
        threshold: threshold,
        image: image, // Pass image to service
      );

      _items.add(newItem);
      _filteredItems.add(newItem);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  final List<Location> _locations = [];
  bool _locationsLoading = false;
  String _locationsErrorMessage = '';

  List<Location> get locations => _locations;
  bool get locationsLoading => _locationsLoading;
  String get locationsErrorMessage => _locationsErrorMessage;

  Future<void> fetchLocations() async {
    _locationsLoading = true;
    _locationsErrorMessage = '';
    notifyListeners();

    try {
      final locations = await _itemsService.getLocations();
      _locations.clear();
      // Only add active locations
      _locations.addAll(locations.where((loc) => loc.isActive));
      _locationsLoading = false;
      notifyListeners();
    } catch (e) {
      _locationsLoading = false;
      _locationsErrorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  void clearLocationsError() {
    _locationsErrorMessage = '';
    notifyListeners();
  }

  Future<void> fetchItems() async {
    // Don't set loading to true if we're already loading
    if (_isLoading) return;

    _isLoading = true;
    _errorMessage = '';
    // Don't notify listeners immediately to avoid setState during build
    Future.microtask(() => notifyListeners());

    try {
      final items = await _itemsService.getItems();
      _items.clear();
      _items.addAll(items);
      _filteredItems.clear();
      _filteredItems.addAll(items); // Initialize filtered items with all items
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  Future<bool> addStock(StockAddRequest request) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      await _itemsService.addStock(request);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  // Helper method to get locations for an item
  List<ItemLocation> getLocationsForItem(String itemId) {
    final item = _items.firstWhere((item) => item.id == itemId, orElse: () => Item(id: '', name: '', locations: []));
    return item.locations;
  }

  void clearError() {
    _errorMessage = '';
    notifyListeners();
  }

  void searchItems(String query) {
    _searchQuery = query;
    _applySearchFilter();
    notifyListeners();
  }

  void clearSearch() {
    _searchQuery = '';
    _applySearchFilter();
    notifyListeners();
  }

  void _applySearchFilter() {
    if (_searchQuery.isEmpty) {
      _filteredItems = List.from(_items); // Reset to all items
    } else {
      _filteredItems = _items
          .where((item) => item.matchesSearch(_searchQuery))
          .toList();
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }


  // Add these methods to your existing ItemsProvider class

// Search Items
  Future<void> searchItemsApi(String query) async {
    if (query.isEmpty) {
      // If search query is empty, show all items
      _filteredItems = List.from(_items);
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final searchResults = await _itemsService.searchItems(query);
      _filteredItems = searchResults;
      _errorMessage = '';
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      // Fallback to local search if API fails
      _filteredItems = _items
          .where((item) => item.matchesSearch(query))
          .toList();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

// Lookup Item by Barcode
  Future<Item?> getItemByBarcode(String barcode) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final item = await _itemsService.getItemByBarcode(barcode);
      _isLoading = false;
      notifyListeners();
      return item;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return null;
    }
  }

// Assign or Generate Barcode
  Future<bool> assignBarcode({
    required String itemId,
    String? barcode,
    bool overwrite = false,
  }) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final updatedItem = await _itemsService.assignBarcode(
        itemId: itemId,
        barcode: barcode,
        overwrite: overwrite,
      );

      // Update the item in the local list
      final index = _items.indexWhere((item) => item.id == itemId);
      if (index != -1) {
        _items[index] = updatedItem;
        _applySearchFilter(); // Update filtered items as well
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

// Get Item by ID
  Future<Item?> getItemById(String id) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final item = await _itemsService.getItemById(id);
      _isLoading = false;
      notifyListeners();
      return item;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return null;
    }
  }

// Update Item
  Future<bool> updateItem({
    required String id,
    required String name,
    required String unit,
    required int threshold,
    required String status,
  }) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final updatedItem = await _itemsService.updateItem(
        id: id,
        name: name,
        unit: unit,
        threshold: threshold,
        status: status,
      );

      // Update the item in the local list
      final index = _items.indexWhere((item) => item.id == id);
      if (index != -1) {
        _items[index] = updatedItem;
        _applySearchFilter(); // Update filtered items as well
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

// Barcode generation utility
  String generateBarcode() {
    // Generate a random 12-digit barcode
    final random = DateTime.now().millisecondsSinceEpoch.toString();
    return random.substring(random.length - 12).padLeft(12, '0');
  }



  // Add these properties and methods to your existing ItemsProvider class

  DashboardData? _dashboardData;
  bool _dashboardLoading = false;
  String _dashboardErrorMessage = '';

  DashboardData? get dashboardData => _dashboardData;
  bool get dashboardLoading => _dashboardLoading;
  String get dashboardErrorMessage => _dashboardErrorMessage;

// Get Dashboard Data
  Future<void> fetchDashboardData() async {
    _dashboardLoading = true;
    _dashboardErrorMessage = '';
    notifyListeners();

    try {
      _dashboardData = await _itemsService.getDashboardData();
      _dashboardErrorMessage = '';
    } catch (e) {
      _dashboardErrorMessage = e.toString().replaceAll('Exception: ', '');
      _dashboardData = null;
    } finally {
      _dashboardLoading = false;
      notifyListeners();
    }
  }

// Clear dashboard error
  void clearDashboardError() {
    _dashboardErrorMessage = '';
    notifyListeners();
  }

}