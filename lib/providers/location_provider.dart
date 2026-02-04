import 'package:flutter/foundation.dart';
import 'package:stock_buddy/models/location_model.dart';
import 'package:stock_buddy/services/location_service.dart';

class LocationProvider with ChangeNotifier {
  final LocationService _locationService;

  List<Location> _locations = [];
  bool _isLoading = false;
  String? _error;

  LocationProvider(this._locationService);

  List<Location> get locations => _locations;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Load all locations
  Future<void> loadLocations() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _locations = await _locationService.getLocations();
      _error = null;
    } catch (e) {
      _error = e.toString();
      _locations = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create new location
  Future<bool> createLocation({
    required String name,
    String? address,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final newLocation = await _locationService.createLocation(
        name: name,
        address: address,
      );

      // Add new location to the list and reload
      await loadLocations();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Update location
  Future<bool> updateLocation({
    required String id,
    required String name,
    required String address,
    required bool isActive,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _locationService.updateLocation(
        id: id,
        name: name,
        address: address,
        isActive: isActive,
      );

      // Reload locations after update
      await loadLocations();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Find location by ID
  Location? getLocationById(String id) {
    try {
      return _locations.firstWhere((location) => location.id == id);
    } catch (e) {
      return null;
    }
  }
}