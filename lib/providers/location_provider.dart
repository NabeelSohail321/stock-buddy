import 'package:flutter/foundation.dart';

import '../core/app_exception.dart';
import '../models/location_model.dart';
import '../services/location_service.dart';

class LocationProvider with ChangeNotifier {
  final LocationService _locationService;

  LocationProvider(this._locationService);

  List<Location> _locations = [];
  bool _isLoading = false;
  String _error = '';

  List<Location> get locations => _locations;
  bool get isLoading => _isLoading;
  String get error => _error;

  Future<void> loadLocations() async {
    _setLoading(true);
    try {
      _locations = await _locationService.getLocations();
    } on AppException catch (e) {
      _error = e.message;
      _locations = [];
    } catch (_) {
      _error = 'Failed to load locations. Please try again.';
      _locations = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createLocation({
    required String name,
    String? address,
  }) async {
    _setLoading(true);
    try {
      final newLocation =
          await _locationService.createLocation(name: name, address: address);
      _locations.add(newLocation);
      _setLoading(false);
      return true;
    } on AppException catch (e) {
      _error = e.message;
      _setLoading(false);
      return false;
    } catch (_) {
      _error = 'Failed to create location. Please try again.';
      _setLoading(false);
      return false;
    }
  }

  Future<bool> updateLocation({
    required String id,
    required String name,
    required String address,
    required bool isActive,
  }) async {
    _setLoading(true);
    try {
      final updated = await _locationService.updateLocation(
        id: id,
        name: name,
        address: address,
        isActive: isActive,
      );
      final idx = _locations.indexWhere((l) => l.id == id);
      if (idx != -1) _locations[idx] = updated;
      _setLoading(false);
      return true;
    } on AppException catch (e) {
      _error = e.message;
      _setLoading(false);
      return false;
    } catch (_) {
      _error = 'Failed to update location. Please try again.';
      _setLoading(false);
      return false;
    }
  }

  Location? getLocationById(String id) {
    try {
      return _locations.firstWhere((l) => l.id == id);
    } catch (_) {
      return null;
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    if (loading) _error = '';
    notifyListeners();
  }

  void clearError() {
    _error = '';
    notifyListeners();
  }
}
