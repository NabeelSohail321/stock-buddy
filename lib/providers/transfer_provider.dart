import 'package:flutter/foundation.dart';
import '../services/transfer_service.dart';

class TransferProvider with ChangeNotifier {
  List<dynamic> _pendingTransfers = [];
  bool _isLoading = false;
  String _error = '';

  List<dynamic> get pendingTransfers => _pendingTransfers;
  bool get isLoading => _isLoading;
  String get error => _error;

  final TransferService _transferService;

  TransferProvider(this._transferService);

  Future<void> fetchPendingTransfers() async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      _pendingTransfers = await _transferService.getPendingTransfers();
      _error = '';
    } catch (e) {
      _error = e.toString();
      _pendingTransfers = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> reviewTransfer({
    required String transactionId,
    required bool approved,
    String note = '',
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _transferService.reviewTransfer(
        transactionId: transactionId,
        approved: approved,
        note: note,
      );

      // Remove the reviewed transfer from the list
      _pendingTransfers.removeWhere((transfer) => transfer['_id'] == transactionId);
      _error = '';
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = '';
    notifyListeners();
  }
}