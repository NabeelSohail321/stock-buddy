import 'package:flutter/foundation.dart';

import '../core/app_exception.dart';
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
  String _error = '';
  String _searchQuery = '';
  final List<Item> _items = [];
  List<Item> _filteredItems = [];

  List<Item> get items => _filteredItems;
  List<Item> get allItems => _items;
  bool get isLoading => _isLoading;
  String get error => _error;
  // Keep errorMessage as alias for backwards-compat with existing screens
  String get errorMessage => _error;
  String get searchQuery => _searchQuery;

  // ── locations (used by some screens via this provider) ──────────────────
  final List<Location> _locations = [];
  bool _locationsLoading = false;
  String _locationsError = '';

  List<Location> get locations => _locations;
  bool get locationsLoading => _locationsLoading;
  String get locationsErrorMessage => _locationsError;

  Future<void> fetchLocations() async {
    _locationsLoading = true;
    _locationsError = '';
    notifyListeners();
    try {
      final locs = await _itemsService.getLocations();
      _locations
        ..clear()
        ..addAll(locs.where((l) => l.isActive));
    } on AppException catch (e) {
      _locationsError = e.message;
    } catch (_) {
      _locationsError = 'Failed to load locations. Please try again.';
    } finally {
      _locationsLoading = false;
      notifyListeners();
    }
  }

  void clearLocationsError() {
    _locationsError = '';
    notifyListeners();
  }

  // ── items ────────────────────────────────────────────────────────────────

  Future<bool> createItem({
    required String name,
    String? sku,
    required String barcode,
    required String unit,
    required int threshold,
    String? locationId,
    String? managerId,
    int initialQuantity = 0,
    String? image,
    String? modelNumber,
    String? serialNumber,
    String? purchaseDate,
  }) async {
    _setLoading(true);
    try {
      final effectiveSku = (sku == null || sku.isEmpty) ? generateSku() : sku;
      final newItem = await _itemsService.createItem(
        name: name,
        sku: effectiveSku,
        barcode: barcode,
        unit: unit,
        threshold: threshold,
        locationId: locationId,
        managerId: managerId,
        initialQuantity: initialQuantity,
        image: image,
        modelNumber: modelNumber,
        serialNumber: serialNumber,
        purchaseDate: purchaseDate,
      );
      _items.add(newItem);
      _filteredItems.add(newItem);
      _setLoading(false);
      return true;
    } on AppException catch (e) {
      _error = e.message;
      _setLoading(false);
      return false;
    } catch (_) {
      _error = 'Failed to create item. Please try again.';
      _setLoading(false);
      return false;
    }
  }

  Future<void> fetchItems() async {
    if (_isLoading) return;
    _setLoading(true);
    try {
      final fetched = await _itemsService.getItems();
      _items
        ..clear()
        ..addAll(fetched);
      _filteredItems
        ..clear()
        ..addAll(fetched);
    } on AppException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'Failed to load items. Please try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addStock(StockAddRequest request) async {
    _setLoading(true);
    try {
      await _itemsService.addStock(request);
      _setLoading(false);
      return true;
    } on AppException catch (e) {
      _error = e.message;
      _setLoading(false);
      return false;
    } catch (_) {
      _error = 'Failed to add stock. Please try again.';
      _setLoading(false);
      return false;
    }
  }

  Future<void> searchItemsApi(String query) async {
    if (query.isEmpty) {
      _filteredItems = List.from(_items);
      notifyListeners();
      return;
    }
    _setLoading(true);
    try {
      _filteredItems = await _itemsService.searchItems(query);
    } on AppException catch (e) {
      _error = e.message;
      _filteredItems = _items.where((i) => i.matchesSearch(query)).toList();
    } catch (_) {
      _filteredItems = _items.where((i) => i.matchesSearch(query)).toList();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Item?> getItemByBarcode(String barcode) async {
    _setLoading(true);
    try {
      final item = await _itemsService.getItemByBarcode(barcode);
      _setLoading(false);
      return item;
    } on AppException catch (e) {
      _error = e.message;
      _setLoading(false);
      return null;
    } catch (_) {
      _error = 'Failed to find item. Please try again.';
      _setLoading(false);
      return null;
    }
  }

  Future<bool> assignBarcode({
    required String itemId,
    String? barcode,
    bool overwrite = false,
  }) async {
    _setLoading(true);
    try {
      final updated = await _itemsService.assignBarcode(
        itemId: itemId,
        barcode: barcode,
        overwrite: overwrite,
      );
      final idx = _items.indexWhere((i) => i.id == itemId);
      if (idx != -1) {
        _items[idx] = updated;
        _applySearchFilter();
      }
      _setLoading(false);
      return true;
    } on AppException catch (e) {
      _error = e.message;
      _setLoading(false);
      return false;
    } catch (_) {
      _error = 'Failed to assign barcode. Please try again.';
      _setLoading(false);
      return false;
    }
  }

  Future<Item?> getItemById(String id) async {
    _setLoading(true);
    try {
      final item = await _itemsService.getItemById(id);
      _setLoading(false);
      return item;
    } on AppException catch (e) {
      _error = e.message;
      _setLoading(false);
      return null;
    } catch (_) {
      _error = 'Failed to load item. Please try again.';
      _setLoading(false);
      return null;
    }
  }

  Future<bool> updateItem({
    required String id,
    required String name,
    required String unit,
    required int threshold,
    required String status,
    String? modelNumber,
    String? serialNumber,
    String? purchaseDate,
  }) async {
    _setLoading(true);
    try {
      final updated = await _itemsService.updateItem(
        id: id,
        name: name,
        unit: unit,
        threshold: threshold,
        status: status,
        modelNumber: modelNumber,
        serialNumber: serialNumber,
        purchaseDate: purchaseDate,
      );
      final idx = _items.indexWhere((i) => i.id == id);
      if (idx != -1) {
        _items[idx] = updated;
        _applySearchFilter();
      }
      _setLoading(false);
      return true;
    } on AppException catch (e) {
      _error = e.message;
      _setLoading(false);
      return false;
    } catch (_) {
      _error = 'Failed to update item. Please try again.';
      _setLoading(false);
      return false;
    }
  }

  List<ItemLocation> getLocationsForItem(String itemId) {
    try {
      return _items.firstWhere((i) => i.id == itemId).locations;
    } catch (_) {
      return [];
    }
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
    _filteredItems = _searchQuery.isEmpty
        ? List.from(_items)
        : _items.where((i) => i.matchesSearch(_searchQuery)).toList();
  }

  // ── dashboard ────────────────────────────────────────────────────────────

  DashboardData? _dashboardData;
  bool _dashboardLoading = false;
  String _dashboardError = '';

  DashboardData? get dashboardData => _dashboardData;
  bool get dashboardLoading => _dashboardLoading;
  String get dashboardErrorMessage => _dashboardError;

  Future<void> fetchDashboardData() async {
    _dashboardLoading = true;
    _dashboardError = '';
    notifyListeners();
    try {
      _dashboardData = await _itemsService.getDashboardData();
    } on AppException catch (e) {
      _dashboardError = e.message;
      _dashboardData = null;
    } catch (_) {
      _dashboardError = 'Failed to load dashboard. Please try again.';
      _dashboardData = null;
    } finally {
      _dashboardLoading = false;
      notifyListeners();
    }
  }

  void clearDashboardError() {
    _dashboardError = '';
    notifyListeners();
  }

  // ── utilities ─────────────────────────────────────────────────────────────

  void _setLoading(bool loading) {
    _isLoading = loading;
    if (loading) _error = '';
    notifyListeners();
  }

  void clearError() {
    _error = '';
    notifyListeners();
  }

  String generateBarcode() {
    final ts = DateTime.now().millisecondsSinceEpoch.toString();
    return ts.substring(ts.length - 12).padLeft(12, '0');
  }

  String generateSku() {
    final ts = DateTime.now().millisecondsSinceEpoch.toString();
    final micro = (DateTime.now().microsecondsSinceEpoch % 10000)
        .toString()
        .padLeft(4, '0');
    return 'SKU-${ts.substring(ts.length - 6)}$micro';
  }
}
