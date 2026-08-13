import 'package:flutter/foundation.dart';
import 'package:printing/printing.dart';

import '../core/app_exception.dart';
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

  // ── Server-side filter state ──────────────────────────────────────────────
  String? _category;
  String? _type;
  String? _status;
  String? _datePreset;
  String? _search;
  String? _startDate;
  String? _endDate;
  String? _locationId;
  String? _managerId;
  String? _itemId;

  TransactionProvider({required TransactionService transactionService})
      : _transactionService = transactionService;

  // ── Getters ───────────────────────────────────────────────────────────────
  List<Transaction> get recentTransactions => _recentTransactions;
  List<Transaction> get allTransactions => _allTransactions;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  bool get hasMore => _hasMore;
  String? get category => _category;
  String? get type => _type;
  String? get status => _status;
  String? get datePreset => _datePreset;
  String? get search => _search;
  String? get startDate => _startDate;
  String? get endDate => _endDate;
  String? get locationId => _locationId;
  String? get managerId => _managerId;
  String? get itemId => _itemId;

  // ── Recent transactions (home screen) ─────────────────────────────────────
  Future<void> loadRecentTransactions() async {
    _setLoading(true);
    _errorMessage = '';
    try {
      final response = await _transactionService.getRecentTransactions(limit: 10);
      _recentTransactions = response['transactions'];
      notifyListeners();
    } on AppException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load recent transactions. Please try again.';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  // ── Full transaction list (transaction screen) ─────────────────────────────
  Future<void> loadAllTransactions({
    String? category,
    String? type,
    String? status,
    String? datePreset,
    String? search,
    String? startDate,
    String? endDate,
    String? locationId,
    String? managerId,
    String? itemId,
    bool loadMore = false,
  }) async {
    try {
      if (!loadMore) {
        _setLoading(true);
        _currentPage = 1;
        _allTransactions = [];
        _hasMore = true;

        // Store all active filters
        _category   = category;
        _type       = type;
        _status     = status;
        _datePreset = datePreset;
        _search     = search;
        _startDate  = startDate;
        _endDate    = endDate;
        _locationId = locationId;
        _managerId  = managerId;
        _itemId     = itemId;
      } else {
        _isLoading = true;
        notifyListeners();
      }

      _errorMessage = '';

      final response = await _transactionService.getTransactions(
        category:   _category,
        type:       _type,
        status:     _status,
        datePreset: _datePreset,
        search:     _search,
        startDate:  _startDate,
        endDate:    _endDate,
        locationId: _locationId,
        managerId:  _managerId,
        itemId:     _itemId,
        page:       _currentPage,
        limit:      50,
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
    } on AppException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load transactions. Please try again.';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadMoreTransactions() async {
    if (_isLoading || !_hasMore) return;

    _currentPage++;
    try {
      await loadAllTransactions(
        category:   _category,
        type:       _type,
        status:     _status,
        datePreset: _datePreset,
        search:     _search,
        startDate:  _startDate,
        endDate:    _endDate,
        locationId: _locationId,
        managerId:  _managerId,
        itemId:     _itemId,
        loadMore:   true,
      );
    } catch (_) {
      _currentPage--;
    }
  }

  // ── PDF export (server-generated, all matching records) ───────────────────
  Future<void> exportTransactionsToPdf() async {
    try {
      _setLoading(true);
      _errorMessage = '';

      // Server generates the PDF with ALL records matching current filters.
      final pdfBytes = await _transactionService.downloadTransactionsPdf(
        category:   _category,
        type:       _type,
        status:     _status,
        datePreset: _datePreset,
        search:     _search,
        startDate:  _startDate,
        endDate:    _endDate,
        locationId: _locationId,
        managerId:  _managerId,
        itemId:     _itemId,
      );

      _setLoading(false);

      // Open share sheet / print dialog — works on iOS and Desktop.
      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: 'transactions_report.pdf',
      );
    } on AppException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to export PDF. Please try again.';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateRepairChecklist(
      String transactionId, List<Map<String, dynamic>> items) async {
    try {
      _setLoading(true);
      final success =
          await _transactionService.updateRepairChecklist(transactionId, items);

      if (success) {
        await loadAllTransactions(
          category:   _category,
          type:       _type,
          status:     _status,
          datePreset: _datePreset,
          search:     _search,
          startDate:  _startDate,
          endDate:    _endDate,
          locationId: _locationId,
          managerId:  _managerId,
          itemId:     _itemId,
        );
      }

      return success;
    } on AppException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Failed to update checklist. Please try again.';
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
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
