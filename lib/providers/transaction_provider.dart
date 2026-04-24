import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:html_to_pdf/html_to_pdf.dart';

import '../models/transaction_model.dart';
import '../services/transaction_service.dart';
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'dart:io';

class TransactionProvider with ChangeNotifier {
  final TransactionService _transactionService;

  List<Transaction> _recentTransactions = [];
  List<Transaction> _allTransactions = [];
  bool _isLoading = false;
  String _errorMessage = '';
  int _currentPage = 1;
  int _totalPages = 1;
  bool _hasMore = true;

  // Filter State
  String? _category;
  String? _type;
  String? _status;
  String? _datePreset;
  String? _search;
  String? _startDate;
  String? _endDate;

  TransactionProvider({required TransactionService transactionService})
      : _transactionService = transactionService;

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
    String? category,
    String? type,
    String? status,
    String? datePreset,
    String? search,
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

        // Update stored filters
        _category = category;
        _type = type;
        _status = status;
        _datePreset = datePreset;
        _search = search;
        _startDate = startDate;
        _endDate = endDate;
      }

      _errorMessage = '';

      final response = await _transactionService.getTransactions(
        category: _category,
        type: _type,
        status: _status,
        datePreset: _datePreset,
        search: _search,
        startDate: _startDate,
        endDate: _endDate,
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

  Future<void> loadMoreTransactions() async {
    if (_isLoading || !_hasMore) return;

    _currentPage++;
    await loadAllTransactions(
      category: _category,
      type: _type,
      status: _status,
      datePreset: _datePreset,
      search: _search,
      startDate: _startDate,
      endDate: _endDate,
      loadMore: true,
    );
  }

  Future<void> exportTransactionsToPdf() async {
    try {
      _setLoading(true);
      _errorMessage = '';

      // Use the currently loaded transactions for the export
      final transactions = _allTransactions;
      
      if (transactions.isEmpty) {
        throw Exception('No transactions to export');
      }

      final htmlContent = _generateExportHtml(transactions);

      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = 'transactions_$timestamp';
      
      final generatedPdfFile = await HtmlToPdf.convertFromHtmlContent(
        htmlContent: htmlContent,
        printPdfConfiguration: PrintPdfConfiguration(
          targetDirectory: directory.path,
          targetName: fileName,
          printSize: PrintSize.A4,
          printOrientation: PrintOrientation.Landscape, // Landscape for better table fit
        ),
      );

      await OpenFile.open(generatedPdfFile.path);
    } catch (e) {
      _errorMessage = 'Failed to export PDF: $e';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  String _generateExportHtml(List<Transaction> transactions) {
    final dateStr = DateFormat('MMM dd, yyyy').format(DateTime.now());
    
    StringBuffer html = StringBuffer();
    html.write('''
    <!DOCTYPE html>
    <html>
    <head>
      <style>
        body { font-family: Arial, sans-serif; margin: 20px; color: #333; }
        .header { text-align: center; margin-bottom: 30px; border-bottom: 2px solid #1a237e; padding-bottom: 10px; }
        .title { fontSize: 24px; font-weight: bold; color: #1a237e; }
        .subtitle { fontSize: 14px; color: #666; margin-top: 5px; }
        table { width: 100%; border-collapse: collapse; margin-top: 20px; table-layout: fixed; }
        th { background-color: #1a237e; color: white; padding: 10px; text-align: left; fontSize: 12px; }
        td { padding: 8px; border-bottom: 1px solid #ddd; fontSize: 11px; vertical-align: top; word-wrap: break-word; }
        .type-badge { padding: 3px 6px; border-radius: 4px; font-weight: bold; fontSize: 10px; color: white; }
        .type-add { background-color: #4caf50; }
        .type-transfer { background-color: #2196f3; }
        .type-repair-out { background-color: #9c27b0; }
        .type-repair-in { background-color: #3f51b5; }
        .type-dispose { background-color: #f44336; }
        .checklist { margin: 0; padding-left: 15px; fontSize: 10px; }
        .checklist-item { margin-bottom: 2px; }
        .completed { color: #4caf50; }
        .pending { color: #f57c00; }
        .footer { margin-top: 30px; text-align: center; fontSize: 10px; color: #999; }
      </style>
    </head>
    <body>
      <div class="header">
        <div class="title">Stock Buddy - Transaction Report</div>
        <div class="subtitle">Generated on $dateStr</div>
      </div>
      
      <table>
        <thead>
          <tr>
            <th style="width: 12%">Date</th>
            <th style="width: 10%">Type</th>
            <th style="width: 15%">Item</th>
            <th style="width: 8%">Qty</th>
            <th style="width: 15%">Location(s)</th>
            <th style="width: 15%">Details</th>
            <th style="width: 25%">Repair Checklist</th>
          </tr>
        </thead>
        <tbody>
    ''');

    for (var tx in transactions) {
      final typeClass = _getTypeClass(tx.type);
      final date = DateFormat('yyyy-MM-dd HH:mm').format(tx.createdAt);
      
      String locations = '';
      if (tx.type == 'TRANSFER') {
        locations = 'From: ${tx.fromLocation ?? tx.fromLocationId ?? "-"}<br>To: ${tx.toLocation ?? tx.toLocationId ?? "-"}';
      } else {
        locations = 'Loc: ${tx.fromLocation ?? tx.fromLocationId ?? "-"}';
      }

      String details = '';
      if (tx.vendorName != null && tx.vendorName!.isNotEmpty) {
        details += 'Vendor: ${tx.vendorName}<br>';
      }
      if (tx.serialNumber != null && tx.serialNumber!.isNotEmpty) {
        details += 'Serial: ${tx.serialNumber}<br>';
      }
      if (tx.note != null && tx.note!.isNotEmpty) {
        details += 'Note: ${tx.note}';
      }

      String checklistHtml = '';
      if (tx.repairReturnChecklist.isNotEmpty) {
        checklistHtml = '<ul class="checklist">';
        for (var item in tx.repairReturnChecklist) {
          final status = item.completed ? '<span class="completed">✓</span>' : '<span class="pending">○</span>';
          checklistHtml += '<li class="checklist-item">$status ${item.label}</li>';
        }
        checklistHtml += '</ul>';
      }

      html.write('''
          <tr>
            <td>$date</td>
            <td><span class="type-badge $typeClass">${tx.displayType}</span></td>
            <td>${tx.itemName}</td>
            <td>${tx.quantity}</td>
            <td>$locations</td>
            <td>$details</td>
            <td>$checklistHtml</td>
          </tr>
      ''');
    }

    html.write('''
        </tbody>
      </table>
      <div class="footer">
        © ${DateTime.now().year} Stock Buddy Inventory Management System
      </div>
    </body>
    </html>
    ''');
    
    return html.toString();
  }

  String _getTypeClass(String type) {
    switch (type) {
      case 'ADD': return 'type-add';
      case 'TRANSFER': return 'type-transfer';
      case 'REPAIR_OUT': return 'type-repair-out';
      case 'REPAIR_IN': return 'type-repair-in';
      case 'DISPOSE': return 'type-dispose';
      default: return '';
    }
  }

  Future<bool> updateRepairChecklist(String transactionId, List<Map<String, dynamic>> items) async {
    try {
      _setLoading(true);
      final success = await _transactionService.updateRepairChecklist(transactionId, items);
      
      if (success) {
        // Update the transaction in the local list if it exists
        final index = _allTransactions.indexWhere((tx) => tx.id == transactionId);
        if (index != -1) {
          // Re-fetch or manually update the local object
          // For simplicity, let's just refresh the current list
          await loadAllTransactions(loadMore: false);
        }
      }
      
      return success;
    } catch (e) {
      _errorMessage = 'Failed to update checklist: $e';
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