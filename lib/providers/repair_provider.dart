import 'package:flutter/foundation.dart';

import '../core/app_exception.dart';
import '../services/repair_service.dart';

class RepairProvider with ChangeNotifier {
  final RepairService _repairService;

  RepairProvider(this._repairService);

  bool _isLoading = false;
  String _error = '';
  String _successMessage = '';
  List<dynamic> _repairTickets = [];

  bool get isLoading => _isLoading;
  String get error => _error;
  String get successMessage => _successMessage;
  List<dynamic> get repairTickets => _repairTickets;
  List<dynamic> get sentRepairTickets =>
      _repairTickets.where((t) => t['status'] == 'sent').toList();

  Future<bool> sendToRepair({
    required String itemId,
    required String locationId,
    required int quantity,
    required String vendorName,
    String? serialNumber,
    String? note,
    String? photo,
  }) async {
    _setLoading(true);
    try {
      await _repairService.sendToRepair(
        itemId: itemId,
        locationId: locationId,
        quantity: quantity,
        vendorName: vendorName,
        serialNumber: serialNumber,
        note: note,
        photo: photo,
      );
      _successMessage = 'Item sent for repair successfully';
      _setLoading(false);
      return true;
    } on AppException catch (e) {
      _error = e.message;
      _setLoading(false);
      return false;
    } catch (e) {
      _error = 'An unexpected error occurred. Please try again.';
      _setLoading(false);
      return false;
    }
  }

  Future<void> fetchRepairTickets() async {
    _setLoading(true);
    try {
      _repairTickets = await _repairService.getRepairTickets();
      _setLoading(false);
    } on AppException catch (e) {
      _error = e.message;
      _setLoading(false);
    } catch (e) {
      _error = 'Failed to load repair tickets. Please try again.';
      _setLoading(false);
    }
  }

  Future<bool> returnFromRepair({
    required String repairTicketId,
    required String locationId,
    String? note,
    List<Map<String, dynamic>>? checklist,
  }) async {
    _setLoading(true);
    try {
      await _repairService.returnFromRepair(
        repairTicketId: repairTicketId,
        locationId: locationId,
        note: note,
        checklist: checklist,
      );
      _successMessage = 'Item returned from repair successfully';
      _repairTickets.removeWhere((t) => t['_id'] == repairTicketId);
      _setLoading(false);
      return true;
    } on AppException catch (e) {
      _error = e.message;
      _setLoading(false);
      return false;
    } catch (e) {
      _error = 'An unexpected error occurred. Please try again.';
      _setLoading(false);
      return false;
    }
  }

  Future<bool> disposeFromRepair({
    required String repairTicketId,
    String? reason,
    String? note,
  }) async {
    _setLoading(true);
    try {
      await _repairService.disposeFromRepair(
        repairTicketId: repairTicketId,
        reason: reason,
        note: note,
      );
      _repairTickets.removeWhere((t) => t['_id'] == repairTicketId);
      _setLoading(false);
      return true;
    } on AppException catch (e) {
      _error = e.message;
      _setLoading(false);
      return false;
    } catch (e) {
      _error = 'An unexpected error occurred. Please try again.';
      _setLoading(false);
      return false;
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

  void clearSuccessMessage() {
    _successMessage = '';
    notifyListeners();
  }
}
