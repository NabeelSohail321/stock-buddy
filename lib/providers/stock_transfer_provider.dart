import 'package:flutter/foundation.dart';

import '../core/app_exception.dart';
import '../models/stock_transfer_model.dart';
import '../services/stock_transfer_service.dart';

class StockTransferProvider with ChangeNotifier {
  final StockTransferService _stockTransferService;

  StockTransferProvider({required StockTransferService stockTransferService})
      : _stockTransferService = stockTransferService;

  bool _isLoading = false;
  String _error = '';
  String _successMessage = '';

  bool get isLoading => _isLoading;
  String get error => _error;
  String get errorMessage => _error;
  String get successMessage => _successMessage;

  Future<bool> transferStock({
    required String itemId,
    required String fromLocationId,
    required String toLocationId,
    required int quantity,
    String? managerId,
    String? note,
  }) async {
    _setLoading(true);
    try {
      final request = StockTransferRequest(
        itemId: itemId,
        fromLocationId: fromLocationId,
        toLocationId: toLocationId,
        quantity: quantity,
        managerId: managerId,
        note: note,
      );
      final response = await _stockTransferService.transferStock(request);
      _successMessage = '${response.message} (Status: ${response.transaction.status})';
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
    if (loading) {
      _error = '';
      _successMessage = '';
    }
    notifyListeners();
  }

  void clearError() {
    _error = '';
    notifyListeners();
  }

  void clearSuccess() {
    _successMessage = '';
    notifyListeners();
  }

  void clearAllMessages() {
    _error = '';
    _successMessage = '';
    notifyListeners();
  }
}
