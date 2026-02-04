import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:typed_data';

import '../../providers/transaction_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/location_provider.dart';
import '../../models/transaction_model.dart';
import '../../models/location_model.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final ScrollController _scrollController = ScrollController();

  // Filter States
  DateTimeRange? _selectedDateRange;
  String? _selectedTransactionType;

  // Transaction Types available
  final List<String> _transactionTypes = [
    'ADD',
    'TRANSFER',
    'REPAIR_OUT',
    'REPAIR_IN',
    'DISPOSE'
  ];

  @override
  void initState() {
    super.initState();
    _loadAllData();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    final transactionProvider = context.read<TransactionProvider>();
    final userProvider = context.read<UserProvider>();
    final locationProvider = context.read<LocationProvider>();

    await Future.wait([
      transactionProvider.loadAllTransactions(),
      userProvider.fetchUsers(),
      locationProvider.loadLocations(),
    ]);
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final transactionProvider = context.read<TransactionProvider>();
      if (transactionProvider.hasMore && !transactionProvider.isLoading) {
        transactionProvider.loadMoreTransactions();
      }
    }
  }

  // Client-side filtering logic
  List<Transaction> _filterTransactions(List<Transaction> transactions) {
    return transactions.where((tx) {
      bool matchesType = true;
      bool matchesDate = true;

      // Filter by Type
      if (_selectedTransactionType != null) {
        matchesType = tx.type == _selectedTransactionType;
      }

      // Filter by Date Range
      if (_selectedDateRange != null) {
        // FIXED: Duration logic
        final start = DateUtils.dateOnly(_selectedDateRange!.start);
        // Add 1 day then subtract 1 second to get 23:59:59 of the end date
        final end = DateUtils.dateOnly(_selectedDateRange!.end)
            .add(const Duration(days: 1))
            .subtract(const Duration(seconds: 1));

        matchesDate = tx.createdAt.isAfter(start) && tx.createdAt.isBefore(end);
      }

      return matchesType && matchesDate;
    }).toList();
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _selectedDateRange,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: Colors.blue.shade800,
            colorScheme: ColorScheme.light(primary: Colors.blue.shade800),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Transactions'),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _loadAllData();
            },
          ),
        ],
      ),
      body: Consumer3<TransactionProvider, UserProvider, LocationProvider>(
        builder: (context, transProv, userProv, locProv, child) {
          // Apply filters to the raw list from provider
          final filteredTransactions = _filterTransactions(transProv.allTransactions);

          return Column(
            children: [
              // --- Filter Section ---
              Container(
                padding: const EdgeInsets.all(12),
                color: Colors.white,
                child: Column(
                  children: [
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          // Date Filter Chip (FIXED: Switched to InputChip)
                          InputChip(
                            avatar: const Icon(Icons.calendar_today, size: 16),
                            label: Text(_selectedDateRange == null
                                ? 'Date Range'
                                : '${DateFormat('MMM d').format(_selectedDateRange!.start)} - ${DateFormat('MMM d').format(_selectedDateRange!.end)}'
                            ),
                            onPressed: _selectDateRange,
                            // Only show delete icon if a date is selected
                            onDeleted: _selectedDateRange != null ? () {
                              setState(() => _selectedDateRange = null);
                            } : null,
                            backgroundColor: _selectedDateRange != null ? Colors.blue.shade100 : null,
                          ),
                          const SizedBox(width: 8),
                          // Type Dropdown
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: _selectedTransactionType != null ? Colors.blue.shade100 : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedTransactionType,
                                hint: Row(
                                  children: [
                                    Icon(Icons.filter_list, size: 16, color: Colors.grey[800]),
                                    const SizedBox(width: 8),
                                    const Text('Type', style: TextStyle(color: Colors.black)),
                                  ],
                                ),
                                icon: const Icon(Icons.arrow_drop_down),
                                onChanged: (String? newValue) {
                                  setState(() {
                                    _selectedTransactionType = newValue;
                                  });
                                },
                                items: [
                                  const DropdownMenuItem<String>(
                                    value: null,
                                    child: Text('All Types'),
                                  ),
                                  ..._transactionTypes.map<DropdownMenuItem<String>>((String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(value),
                                    );
                                  }).toList(),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Clear All Button
                          if (_selectedDateRange != null || _selectedTransactionType != null)
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _selectedDateRange = null;
                                  _selectedTransactionType = null;
                                });
                              },
                              child: const Text('Clear All'),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // --- List Section ---
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _loadAllData,
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(12),
                    itemCount: filteredTransactions.length + 1,
                    itemBuilder: (context, index) {

                      if (index == filteredTransactions.length) {
                        return Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Center(
                            child: transProv.isLoading
                                ? const CircularProgressIndicator()
                                : transProv.hasMore
                                ? OutlinedButton(
                              onPressed: () => transProv.loadMoreTransactions(),
                              child: const Text("Load More Data"),
                            )
                                : const Text(
                                'No more transactions',
                                style: TextStyle(color: Colors.grey)
                            ),
                          ),
                        );
                      }

                      final transaction = filteredTransactions[index];
                      return _buildTransactionCard(transaction, userProv, locProv);
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTransactionCard(
      Transaction transaction,
      UserProvider userProv,
      LocationProvider locProv
      ) {

    String getUserName(String? userId) {
      if (userId == null) return '';
      try {
        final user = userProv.users.firstWhere(
              (u) => u['_id'] == userId || u['id'] == userId,
          orElse: () => null,
        );
        return user != null ? user['name'] ?? 'Unknown User' : 'Unknown User';
      } catch (e) {
        return 'Unknown User';
      }
    }

    String getLocationName(String? locId) {
      if (locId == null) return '';
      final Location? loc = locProv.getLocationById(locId);
      return loc != null ? loc.name : 'Unknown Location';
    }

    final createdByName = getUserName(transaction.createdBy);
    final approvedByName = getUserName(transaction.approvedBy);
    final fromLocName = getLocationName(transaction.fromLocationId);
    final toLocName = getLocationName(transaction.toLocationId);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _getTypeColor(transaction.type).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: _getTypeColor(transaction.type)),
                  ),
                  child: Text(
                    transaction.displayType,
                    style: TextStyle(
                      color: _getTypeColor(transaction.type),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                if (transaction.status != null)
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getStatusColor(transaction.status!).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      transaction.status!.toUpperCase(),
                      style: TextStyle(
                        color: _getStatusColor(transaction.status!),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                const Spacer(),
                Text(
                  _formatDate(transaction.createdAt),
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
            const Divider(height: 20),
            Text(
              transaction.itemName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 12),
            _buildDetailRow(Icons.inventory_2_outlined, 'Quantity:', '${transaction.quantity}'),
            if (transaction.type == 'TRANSFER' && transaction.toLocationId != null) ...[
              _buildDetailRow(Icons.output_outlined, 'From:', fromLocName),
              _buildDetailRow(Icons.input_outlined, 'To:', toLocName),
            ] else if (transaction.fromLocationId != null) ...[
              _buildDetailRow(Icons.location_on_outlined, 'Location:', fromLocName),
            ],
            if (transaction.reason != null && transaction.reason!.isNotEmpty)
              _buildDetailRow(Icons.question_mark_rounded, 'Reason:', transaction.reason!),
            if (transaction.note != null && transaction.note!.isNotEmpty)
              _buildDetailRow(Icons.note_alt_outlined, 'Note:', transaction.note!),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  _buildDetailRow(Icons.person_outline, 'Created By:', createdByName),
                  if (transaction.approvedBy != null) ...[
                    const SizedBox(height: 4),
                    _buildDetailRow(Icons.verified_user_outlined, 'Approved By:', approvedByName),
                  ],
                  if (transaction.approvedAt != null) ...[
                    const SizedBox(height: 4),
                    _buildDetailRow(Icons.calendar_month_outlined, 'Approved At:', _formatDate(transaction.approvedAt!)),
                  ],
                ],
              ),
            ),
            if (transaction.photo != null && transaction.photo!.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'Attachment:',
                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 4),
              InkWell(
                onTap: () => _showFullScreenImage(context, transaction.photo!),
                child: Container(
                  height: 100,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: _buildImageFromBase64(transaction.photo!),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[800],
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageFromBase64(String base64Image) {
    try {
      String cleanBase64 = base64Image;
      if (base64Image.contains(',')) {
        cleanBase64 = base64Image.split(',').last;
      }
      Uint8List bytes = base64Decode(cleanBase64);
      return Image.memory(bytes, fit: BoxFit.cover);
    } catch (e) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.broken_image, color: Colors.grey),
            Text("Image Error", style: TextStyle(fontSize: 10)),
          ],
        ),
      );
    }
  }

  void _showFullScreenImage(BuildContext context, String base64Image) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: _buildImageFromBase64(base64Image),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: Colors.black54,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'ADD':
        return Colors.green;
      case 'TRANSFER':
        return Colors.blue;
      case 'REPAIR_OUT':
        return Colors.purple;
      case 'REPAIR_IN':
        return Colors.indigo;
      case 'DISPOSE':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.blueGrey;
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy HH:mm').format(date);
  }
}