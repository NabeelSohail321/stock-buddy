import 'package:flutter/foundation.dart';
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

  // Existing sendToRepair method...
  Future<bool> sendToRepair({
    required String itemId,
    required String locationId,
    required int quantity,
    required String vendorName,
    String? serialNumber,
    String? note,
    String? photo,
  }) async {
    _isLoading = true;
    _error = '';
    _successMessage = '';
    notifyListeners();

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
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // New method to fetch repair tickets
  Future<void> fetchRepairTickets() async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      _repairTickets = await _repairService.getRepairTickets();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // New method to return from repair
  Future<bool> returnFromRepair({
    required String repairTicketId,
    required String locationId,
    String? note,
  }) async {
    _isLoading = true;
    _error = '';
    _successMessage = '';
    notifyListeners();

    try {
      await _repairService.returnFromRepair(
        repairTicketId: repairTicketId,
        locationId: locationId,
        note: note,
      );

      _successMessage = 'Item returned from repair successfully';

      // Remove the returned ticket from the list
      _repairTickets.removeWhere((ticket) => ticket['_id'] == repairTicketId);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = '';
    notifyListeners();
  }

  void clearSuccessMessage() {
    _successMessage = '';
    notifyListeners();
  }

  // Helper method to get only sent repair tickets (not returned)
  List<dynamic> get sentRepairTickets {
    return _repairTickets.where((ticket) => ticket['status'] == 'sent').toList();
  }
}