import 'package:flutter/foundation.dart';

import '../core/app_exception.dart';
import '../models/manager_model.dart';
import '../services/manager_service.dart';

class ManagerProvider with ChangeNotifier {
  final ManagerService _service;

  ManagerProvider(this._service);

  bool _isLoading = false;
  String _error = '';
  List<Manager> _managers = [];
  List<Manager> _locationManagers = [];

  bool get isLoading => _isLoading;
  String get error => _error;
  List<Manager> get managers => _managers;
  List<Manager> get locationManagers => _locationManagers;

  Future<void> fetchManagers({bool includeInactive = false}) async {
    _setLoading(true);
    try {
      final data = await _service.getManagers(includeInactive: includeInactive);
      _managers = data.map((m) => Manager.fromJson(m)).toList();
    } on AppException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'Failed to load managers. Please try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createManager({
    required String name,
    required String email,
    String? phone,
    List<String> assignedLocationIds = const [],
    Map<String, bool> notificationPreferences = const {
      'stock': true,
      'repair': true,
      'disposal': true,
      'transfer': true,
    },
  }) async {
    _setLoading(true);
    try {
      await _service.createManager(
        name: name,
        email: email,
        phone: phone,
        assignedLocationIds: assignedLocationIds,
        notificationPreferences: notificationPreferences,
      );
      await fetchManagers();
      return true;
    } on AppException catch (e) {
      _error = e.message;
      _setLoading(false);
      return false;
    } catch (_) {
      _error = 'Failed to create manager. Please try again.';
      _setLoading(false);
      return false;
    }
  }

  Future<bool> updateManager({
    required String managerId,
    required String name,
    required String email,
    String? phone,
    List<String> assignedLocationIds = const [],
    Map<String, bool> notificationPreferences = const {
      'stock': true,
      'repair': true,
      'disposal': true,
      'transfer': true,
    },
    bool isActive = true,
  }) async {
    _setLoading(true);
    try {
      final result = await _service.updateManager(
        managerId: managerId,
        name: name,
        email: email,
        phone: phone,
        assignedLocationIds: assignedLocationIds,
        notificationPreferences: notificationPreferences,
        isActive: isActive,
      );
      // GET /managers/:id returns the manager unwrapped. Use it for most fields
      // (especially populated location names), but force-apply the submitted
      // notificationPreferences so the UI always reflects what the user saved,
      // even if the backend subdocument merge doesn't persist correctly.
      final fromApi = Manager.fromJson(result);
      final updated = Manager(
        id: fromApi.id,
        name: fromApi.name,
        email: fromApi.email,
        phone: fromApi.phone,
        assignedLocationIds: fromApi.assignedLocationIds,
        assignedLocationNames: fromApi.assignedLocationNames,
        isActive: fromApi.isActive,
        notificationPreferences: ManagerNotificationPreferences(
          stock: notificationPreferences['stock'] ?? fromApi.notificationPreferences.stock,
          repair: notificationPreferences['repair'] ?? fromApi.notificationPreferences.repair,
          disposal: notificationPreferences['disposal'] ?? fromApi.notificationPreferences.disposal,
          transfer: notificationPreferences['transfer'] ?? fromApi.notificationPreferences.transfer,
        ),
      );
      final idx = _managers.indexWhere((m) => m.id == managerId);
      if (idx != -1) {
        _managers[idx] = updated;
      } else {
        _managers.add(updated);
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } on AppException catch (e) {
      _error = e.message;
      _setLoading(false);
      return false;
    } catch (_) {
      _error = 'Failed to update manager. Please try again.';
      _setLoading(false);
      return false;
    }
  }

  Future<void> fetchManagersByLocation(String locationId) async {
    try {
      final data = await _service.getManagersByLocation(locationId);
      _locationManagers = data.map((m) => Manager.fromJson(m)).toList();
      notifyListeners();
    } catch (_) {
      _locationManagers = [];
      notifyListeners();
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
