import 'package:flutter/foundation.dart';
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

  // Get stock by location
  Future<void> getStockByLocation(String locationId) async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      _locationStock = await _stockService.getStockByLocation(locationId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
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