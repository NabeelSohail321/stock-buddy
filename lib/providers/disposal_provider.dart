import 'package:flutter/foundation.dart';
import '../services/disposal_service.dart';

class DisposalProvider with ChangeNotifier {
  final DisposalService _disposalService;

  DisposalProvider(this._disposalService);

  bool _isLoading = false;
  String _error = '';
  String _successMessage = '';
  List<dynamic> _pendingDisposals = [];

  bool get isLoading => _isLoading;
  String get error => _error;
  String get successMessage => _successMessage;
  List<dynamic> get pendingDisposals => _pendingDisposals;

  // Existing requestDisposal method...
  Future<bool> requestDisposal({
    required String itemId,
    required String locationId,
    required int quantity,
    required String reason,
    String? note,
    required String photo,
  }) async {
    _isLoading = true;
    _error = '';
    _successMessage = '';
    notifyListeners();

    try {
      await _disposalService.requestDisposal(
        itemId: itemId,
        locationId: locationId,
        quantity: quantity,
        reason: reason,
        note: note,
        photo: photo,
      );

      _successMessage = 'Disposal request submitted successfully! Waiting for admin approval.';
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

  // New method to fetch pending disposals
  Future<void> fetchPendingDisposals() async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      _pendingDisposals = await _disposalService.getPendingDisposals();
      print(pendingDisposals);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // New method to approve/reject disposal
  Future<bool> approveDisposal({
    required String transactionId,
    required bool approved,
  }) async {
    _isLoading = true;
    _error = '';
    _successMessage = '';
    notifyListeners();

    try {
      await _disposalService.approveDisposal(
        transactionId: transactionId,
        approved: approved,
      );

      _successMessage = approved
          ? 'Disposal request approved successfully!'
          : 'Disposal request rejected successfully!';

      // Remove the processed disposal from the list
      _pendingDisposals.removeWhere((disposal) => disposal['_id'] == transactionId);

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
}