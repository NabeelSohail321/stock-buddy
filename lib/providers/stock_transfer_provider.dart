import 'package:flutter/foundation.dart';

import '../models/stock_transfer_model.dart';
import '../services/stock_transfer_service.dart';

class StockTransferProvider with ChangeNotifier {
  final StockTransferService _stockTransferService;

  StockTransferProvider({required StockTransferService stockTransferService})
      : _stockTransferService = stockTransferService;

  bool _isLoading = false;
  String _errorMessage = '';
  String _successMessage = '';

  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  String get successMessage => _successMessage;

  Future<bool> transferStock({
    required String itemId,
    required String fromLocationId,
    required String toLocationId,
    required int quantity,
    String? note,
  }) async {
    _isLoading = true;
    _errorMessage = '';
    _successMessage = '';
    notifyListeners();

    try {
      final request = StockTransferRequest(
        itemId: itemId,
        fromLocationId: fromLocationId,
        toLocationId: toLocationId,
        quantity: quantity,
        note: note,
      );

      final response = await _stockTransferService.transferStock(request);

      _successMessage = '${response.message} (Status: ${response.transaction.status})';
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = '';
    notifyListeners();
  }

  void clearSuccess() {
    _successMessage = '';
    notifyListeners();
  }

  void clearAllMessages() {
    _errorMessage = '';
    _successMessage = '';
    notifyListeners();
  }
}