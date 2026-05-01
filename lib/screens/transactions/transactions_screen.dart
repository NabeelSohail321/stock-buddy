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
  String? _selectedCategory;
  String? _selectedTransactionType;
  String? _selectedStatus;
  String? _selectedDatePreset;
  DateTimeRange? _selectedDateRange;
  final TextEditingController _searchController = TextEditingController();

  // Transaction Types available
  final List<String> _transactionTypes = [
    'ADD',
    'TRANSFER',
    'REPAIR_OUT',
    'REPAIR_IN',
    'DISPOSE'
  ];

  final List<Map<String, dynamic>> _categoryOptions = [
    {'id': 'all', 'label': 'All Transactions', 'icon': Icons.list_alt, 'color': Colors.blue},
    {'id': 'add', 'label': 'Stock Added', 'icon': Icons.add_circle_outline, 'color': Colors.green},
    {'id': 'transfers', 'label': 'Transfers', 'icon': Icons.compare_arrows, 'color': Colors.orange},
    {'id': 'sent_repair', 'label': 'Sent to Repair', 'icon': Icons.build_circle_outlined, 'color': Colors.purple},
    {'id': 'returned_repair', 'label': 'Returned from Repair', 'icon': Icons.assignment_return_outlined, 'color': Colors.teal},
    {'id': 'disposed', 'label': 'Disposed', 'icon': Icons.delete_outline, 'color': Colors.red},
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
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    final transactionProvider = context.read<TransactionProvider>();
    final userProvider = context.read<UserProvider>();
    final locationProvider = context.read<LocationProvider>();

    await Future.wait([
      transactionProvider.loadAllTransactions(
        category: _selectedCategory,
        type: _selectedTransactionType,
        status: _selectedStatus,
        datePreset: _selectedDatePreset,
        search: _searchController.text.isNotEmpty ? _searchController.text : null,
        startDate: _selectedDateRange?.start.toIso8601String(),
        endDate: _selectedDateRange?.end.toIso8601String(),
      ),
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

  void _applyFilters() {
    final transProv = context.read<TransactionProvider>();
    transProv.loadAllTransactions(
      category: _selectedCategory,
      type: _selectedTransactionType,
      status: _selectedStatus,
      datePreset: _selectedDatePreset,
      search: _searchController.text.isNotEmpty ? _searchController.text : null,
      startDate: _selectedDateRange?.start.toIso8601String(),
      endDate: _selectedDateRange?.end != null 
          ? _selectedDateRange!.end.add(const Duration(hours: 23, minutes: 59, seconds: 59)).toIso8601String()
          : null,
    );
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
      _applyFilters();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(_selectedCategory == null 
            ? 'Transactions' 
            : _categoryOptions.firstWhere((c) => c['id'] == _selectedCategory)['label']),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
        leading: _selectedCategory != null 
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() => _selectedCategory = null),
              )
            : null,
        actions: [
          if (_selectedCategory != null)
            Consumer<TransactionProvider>(
              builder: (context, transProv, _) {
                if (transProv.isLoading) {
                  return const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    ),
                  );
                }
                return IconButton(
                  icon: const Icon(Icons.picture_as_pdf),
                  onPressed: () async {
                    await transProv.exportTransactionsToPdf();
                    if (transProv.errorMessage.isNotEmpty && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(transProv.errorMessage),
                          backgroundColor: Colors.red,
                        ),
                      );
                      transProv.clearError();
                    }
                  },
                  tooltip: 'Download PDF',
                );
              },
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAllData,
          ),
        ],
      ),
      body: _selectedCategory == null 
          ? _buildCategoryGrid() 
          : _buildTransactionList(),
    );
  }

  Widget _buildCategoryGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.1,
      ),
      itemCount: _categoryOptions.length,
      itemBuilder: (context, index) {
        final category = _categoryOptions[index];
        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: InkWell(
            onTap: () {
              setState(() => _selectedCategory = category['id']);
              _applyFilters();
            },
            borderRadius: BorderRadius.circular(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(category['icon'], size: 48, color: category['color']),
                const SizedBox(height: 12),
                Text(
                  category['label'],
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTransactionList() {
    return Consumer3<TransactionProvider, UserProvider, LocationProvider>(
      builder: (context, transProv, userProv, locProv, child) {
        return Column(
          children: [
            // --- Advanced Filter Bar ---
            _buildAdvancedFilterBar(),
            const Divider(height: 1),

            // --- List Section ---
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadAllData,
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(12),
                  itemCount: transProv.allTransactions.length + 1,
                  itemBuilder: (context, index) {
                    if (index == transProv.allTransactions.length) {
                      return _buildLoadMoreIndicator(transProv);
                    }

                    final transaction = transProv.allTransactions[index];
                    return _buildTransactionCard(transaction, userProv, locProv);
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAdvancedFilterBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.white,
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search items or notes...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              suffixIcon: _searchController.text.isNotEmpty 
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _applyFilters();
                      },
                    )
                  : null,
            ),
            onSubmitted: (_) => _applyFilters(),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterDropdown(
                  value: _selectedDatePreset,
                  hint: 'Date Preset',
                  items: ['day', 'week', 'month', 'year'],
                  onChanged: (val) {
                    setState(() => _selectedDatePreset = val);
                    _applyFilters();
                  },
                ),
                const SizedBox(width: 8),
                _buildFilterDropdown(
                  value: _selectedStatus,
                  hint: 'Status',
                  items: ['pending', 'approved', 'rejected'],
                  onChanged: (val) {
                    setState(() => _selectedStatus = val);
                    _applyFilters();
                  },
                ),
                const SizedBox(width: 8),
                if (_selectedDatePreset == null)
                  InputChip(
                    avatar: const Icon(Icons.calendar_today, size: 16),
                    label: Text(_selectedDateRange == null
                        ? 'Custom Date'
                        : '${DateFormat('MMM d').format(_selectedDateRange!.start)} - ${DateFormat('MMM d').format(_selectedDateRange!.end)}'),
                    onPressed: _selectDateRange,
                    onDeleted: _selectedDateRange != null ? () {
                      setState(() => _selectedDateRange = null);
                      _applyFilters();
                    } : null,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown({
    required String? value,
    required String hint,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: value != null ? Colors.blue.shade100 : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(20),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(hint),
          items: [
            DropdownMenuItem(value: null, child: Text('All $hint')),
            ...items.map((e) => DropdownMenuItem(value: e, child: Text(e.toUpperCase()))),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildLoadMoreIndicator(TransactionProvider transProv) {
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
                : const Text('No more transactions', style: TextStyle(color: Colors.grey)),
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
            if (transaction.vendorName != null && transaction.vendorName!.isNotEmpty)
              _buildDetailRow(Icons.business_outlined, 'Vendor:', transaction.vendorName!),
            if (transaction.serialNumber != null && transaction.serialNumber!.isNotEmpty)
              _buildDetailRow(Icons.pin_outlined, 'Serial No:', transaction.serialNumber!),
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
                  if (transaction.updatedAt != null && transaction.updatedAt!.difference(transaction.createdAt).inSeconds.abs() > 60) ...[
                    const SizedBox(height: 4),
                    _buildDetailRow(Icons.update_outlined, 'Last Updated:', _formatDate(transaction.updatedAt!)),
                  ],
                ],
              ),
            ),
            if (transaction.repairReturnChecklist.isNotEmpty) ...[
              const Divider(height: 24),
              _buildChecklistSection(context, transaction),
            ],
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

  Widget _buildChecklistSection(BuildContext context, Transaction transaction) {
    return InkWell(
      onTap: () => _showChecklistPopup(context, transaction),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue.shade100),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.checklist_rtl, color: Colors.blue.shade800, size: 20),
            const SizedBox(width: 8),
            Text(
              'Tap to show repair check list',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.blue.shade800,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.blue.shade800,
                shape: BoxShape.circle,
              ),
              child: Text(
                '${transaction.repairReturnChecklist.length}',
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showChecklistPopup(BuildContext context, Transaction transaction) {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.checklist_rtl, color: Colors.blue),
                const SizedBox(width: 10),
                const Expanded(child: Text('Repair Check List')),
                // Note: Checklist editing is now disabled per user request
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: transaction.repairReturnChecklist.length,
                itemBuilder: (context, index) {
                  final item = transaction.repairReturnChecklist[index];
                  return CheckboxListTile(
                    title: Text(
                      item.label,
                      style: TextStyle(
                        decoration: item.completed ? TextDecoration.lineThrough : null,
                        color: item.completed ? Colors.grey : Colors.black87,
                      ),
                    ),
                    value: item.completed,
                    onChanged: null, // Editing disabled
                    controlAffinity: ListTileControlAffinity.leading,
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<bool> _saveChecklistChanges(BuildContext context, Transaction transaction) async {
    final transProv = context.read<TransactionProvider>();
    
    // Prepare items for PATCH
    final items = transaction.repairReturnChecklist.map((e) => {
      'id': e.id,
      'completed': e.completed,
    }).toList();

    final success = await transProv.updateRepairChecklist(transaction.id, items);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Checklist updated successfully' : 'Failed to update checklist'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
    return success;
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