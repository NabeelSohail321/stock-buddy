import 'package:flutter/foundation.dart';

import '../core/app_exception.dart';
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

  Future<bool> requestDisposal({
    required String itemId,
    required String locationId,
    required int quantity,
    required String reason,
    String? note,
    required String photo,
  }) async {
    _setLoading(true);
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

  Future<void> fetchPendingDisposals() async {
    _setLoading(true);
    try {
      _pendingDisposals = await _disposalService.getPendingDisposals();
      _setLoading(false);
    } on AppException catch (e) {
      _error = e.message;
      _setLoading(false);
    } catch (e) {
      _error = 'Failed to load disposals. Please try again.';
      _setLoading(false);
    }
  }

  Future<bool> approveDisposal({
    required String transactionId,
    required bool approved,
  }) async {
    _setLoading(true);
    try {
      await _disposalService.approveDisposal(
        transactionId: transactionId,
        approved: approved,
      );
      _successMessage = approved
          ? 'Disposal request approved successfully!'
          : 'Disposal request rejected successfully!';
      _pendingDisposals.removeWhere((d) => d['_id'] == transactionId);
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
