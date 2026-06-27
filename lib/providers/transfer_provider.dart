import 'package:flutter/foundation.dart';

import '../core/app_exception.dart';
import '../services/transfer_service.dart';

class TransferProvider with ChangeNotifier {
  final TransferService _transferService;

  TransferProvider(this._transferService);

  List<dynamic> _pendingTransfers = [];
  bool _isLoading = false;
  String _error = '';

  List<dynamic> get pendingTransfers => _pendingTransfers;
  bool get isLoading => _isLoading;
  String get error => _error;

  Future<void> fetchPendingTransfers() async {
    _setLoading(true);
    try {
      _pendingTransfers = await _transferService.getPendingTransfers();
      _setLoading(false);
    } on AppException catch (e) {
      _error = e.message;
      _pendingTransfers = [];
      _setLoading(false);
    } catch (e) {
      _error = 'Failed to load pending transfers. Please try again.';
      _pendingTransfers = [];
      _setLoading(false);
    }
  }

  Future<bool> reviewTransfer({
    required String transactionId,
    required bool approved,
    String note = '',
  }) async {
    _setLoading(true);
    try {
      await _transferService.reviewTransfer(
        transactionId: transactionId,
        approved: approved,
        note: note,
      );
      _pendingTransfers.removeWhere((t) => t['_id'] == transactionId);
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
}
