import 'package:flutter/foundation.dart';

import '../models/transaction_model.dart';
import '../services/transaction_service.dart';

class TransactionProvider with ChangeNotifier {
  final TransactionService _transactionService;

  List<Transaction> _recentTransactions = [];
  List<Transaction> _allTransactions = [];
  bool _isLoading = false;
  String _errorMessage = '';
  int _currentPage = 1;
  int _totalPages = 1;
  bool _hasMore = true;

  TransactionProvider({required TransactionService transactionService})
      : _transactionService = transactionService;

  List<Transaction> get recentTransactions => _recentTransactions;
  List<Transaction> get allTransactions => _allTransactions;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  bool get hasMore => _hasMore;

  Future<void> loadRecentTransactions() async {
    try {
      _setLoading(true);
      _errorMessage = '';

      final response = await _transactionService.getRecentTransactions(limit: 10);

      _recentTransactions = response['transactions'];
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load recent transactions: $e';
      notifyListeners();
      print('Error in loadRecentTransactions: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadAllTransactions({
    String? type,
    String? status,
    String? startDate,
    String? endDate,
    bool loadMore = false,
  }) async {
    try {
      if (!loadMore) {
        _setLoading(true);
        _currentPage = 1;
        _allTransactions = [];
        _hasMore = true;
      }

      _errorMessage = '';

      final response = await _transactionService.getTransactions(
        type: type,
        status: status,
        startDate: startDate,
        endDate: endDate,
        page: _currentPage,
        limit: 50,
      );

      final List<Transaction> newTransactions = response['transactions'];
      _totalPages = response['totalPages'];

      if (loadMore) {
        _allTransactions.addAll(newTransactions);
      } else {
        _allTransactions = newTransactions;
      }

      _hasMore = _currentPage < _totalPages;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load transactions: $e';
      notifyListeners();
      print('Error in loadAllTransactions: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadMoreTransactions({
    String? type,
    String? status,
    String? startDate,
    String? endDate,
  }) async {
    if (_isLoading || !_hasMore) return;

    _currentPage++;
    await loadAllTransactions(
      type: type,
      status: status,
      startDate: startDate,
      endDate: endDate,
      loadMore: true,
    );
  }

  void clearError() {
    _errorMessage = '';
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}