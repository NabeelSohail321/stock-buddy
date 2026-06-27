import 'package:flutter/foundation.dart';

import '../core/app_exception.dart';
import '../services/stock_service.dart';

class StockProvider with ChangeNotifier {
  final StockService _stockService;

  StockProvider(this._stockService);

  bool _isLoading = false;
  String _error = '';
  List<dynamic> _locationStock = [];

  bool get isLoading => _isLoading;
  String get error => _error;
  List<dynamic> get locationStock => _locationStock;

  Future<void> getStockByLocation(String locationId) async {
    _setLoading(true);
    try {
      _locationStock = await _stockService.getStockByLocation(locationId);
      _setLoading(false);
    } on AppException catch (e) {
      _error = e.message;
      _setLoading(false);
    } catch (e) {
      _error = 'Failed to load stock data. Please try again.';
      _setLoading(false);
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

  void clearStockData() {
    _locationStock = [];
    notifyListeners();
  }
}
