import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/transaction_model.dart';
import '../services/transaction_service.dart';
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

      final transactions = _allTransactions;
      if (transactions.isEmpty) throw Exception('No transactions to export');

      // Generate PDF in pure Dart (No native WebView = No crashes!)
      final pdf = pw.Document();
      final dateStr = DateFormat('MMM dd, yyyy').format(DateTime.now());

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(32),
          build: (context) => [
            _buildPdfHeader(dateStr),
            pw.SizedBox(height: 20),
            _buildPdfTable(transactions),
            _buildPdfFooter(),
          ],
        ),
      );

      final pdfBytes = await pdf.save();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = 'transactions_$timestamp.pdf';

      _setLoading(false);

      // THE ULTIMATE IOS SOLUTION:
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfBytes,
        name: fileName,
      );
    } catch (e) {
      _errorMessage = 'Failed to export PDF: $e';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  pw.Widget _buildPdfHeader(String date) {
    return pw.Container(
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: PdfColors.indigo, width: 2)),
      ),
      padding: const pw.EdgeInsets.only(bottom: 10),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Stock Buddy',
                  style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo)),
              pw.Text('Transaction Report', style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey700)),
            ],
          ),
          pw.Text('Generated: $date', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
        ],
      ),
    );
  }

  pw.Widget _buildPdfTable(List<Transaction> transactions) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FlexColumnWidth(1.2), // Date
        1: const pw.FlexColumnWidth(0.8), // Type
        2: const pw.FlexColumnWidth(1.5), // Item
        3: const pw.FlexColumnWidth(0.5), // Qty
        4: const pw.FlexColumnWidth(1.5), // Location
        5: const pw.FlexColumnWidth(1.5), // Details
        6: const pw.FlexColumnWidth(2.0), // Checklist
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.indigo),
          children: [
            _tableHeader('Date'),
            _tableHeader('Type'),
            _tableHeader('Item'),
            _tableHeader('Qty'),
            _tableHeader('Location'),
            _tableHeader('Details'),
            _tableHeader('Checklist'),
          ],
        ),
        ...transactions.map((tx) {
          final date = DateFormat('yyyy-MM-dd HH:mm').format(tx.createdAt);
          return pw.TableRow(
            children: [
              _tableCell(_sanitize(date)),
              pw.Padding(
                padding: const pw.EdgeInsets.all(5),
                child: pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: pw.BoxDecoration(
                    color: _getPdfTypeColor(tx.type),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                  ),
                  child: pw.Text(_sanitize(tx.displayType),
                      style: const pw.TextStyle(fontSize: 8, color: PdfColors.white, fontWeight: pw.FontWeight.bold)),
                ),
              ),
              _tableCell(_sanitize(tx.itemName)),
              _tableCell(_sanitize('${tx.quantity}')),
              _tableCell(tx.type == 'TRANSFER'
                  ? 'From: ${_sanitize(tx.fromLocation ?? "-")}\nTo: ${_sanitize(tx.toLocation ?? "-")}'
                  : 'Loc: ${_sanitize(tx.fromLocation ?? "-")}'),
              _tableCell(_getPdfDetails(tx)),
              pw.Padding(
                padding: const pw.EdgeInsets.all(5),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: tx.repairReturnChecklist.map((item) {
                    return pw.Text('${item.completed ? "[x]" : "[ ]"} ${_sanitize(item.label)}',
                        style: const pw.TextStyle(fontSize: 8));
                  }).toList(),
                ),
              ),
            ],
          );
        }),
      ],
    );
  }

  pw.Widget _tableHeader(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(text,
          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
    );
  }

  pw.Widget _tableCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(text, style: const pw.TextStyle(fontSize: 8)),
    );
  }

  String _getPdfDetails(Transaction tx) {
    List<String> details = [];
    if (tx.vendorName?.isNotEmpty ?? false) details.add('Vendor: ${_sanitize(tx.vendorName)}');
    if (tx.serialNumber?.isNotEmpty ?? false) details.add('Serial: ${_sanitize(tx.serialNumber)}');
    if (tx.note?.isNotEmpty ?? false) details.add('Note: ${_sanitize(tx.note)}');
    return details.join('\n');
  }

  String _sanitize(String? text) {
    if (text == null) return '';
    // Replace non-ASCII characters to avoid PDF font issues
    return text.replaceAll(RegExp(r'[^\x00-\x7F]'), '?');
  }

  PdfColor _getPdfTypeColor(String type) {
    switch (type) {
      case 'ADD': return PdfColors.green;
      case 'TRANSFER': return PdfColors.blue;
      case 'REPAIR_OUT': return PdfColors.purple;
      case 'REPAIR_IN': return PdfColors.indigo;
      case 'DISPOSE': return PdfColors.red;
      default: return PdfColors.grey;
    }
  }

  pw.Widget _buildPdfFooter() {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 20),
      alignment: pw.Alignment.center,
      child: pw.Text('© ${DateTime.now().year} Stock Buddy Inventory Management System',
          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey)),
    );
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