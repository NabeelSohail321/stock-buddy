import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/location_model.dart';
import '../../models/manager_model.dart';
import '../../models/transaction_model.dart';
import '../../providers/location_provider.dart';
import '../../providers/manager_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../utils/snackbar_utils.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  // All filters are server-side — sent directly in each API request.
  String? _selectedCategory;
  String? _selectedTransactionType;
  String? _selectedStatus;
  String? _selectedDatePreset;
  DateTimeRange? _selectedDateRange;
  String? _selectedLocationId;
  String? _selectedManagerId;
  String? _selectedItemId;

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

  // 'all' is a UI-only sentinel meaning "no category filter" — never sent to the API.
  String? get _apiCategory =>
      (_selectedCategory == null || _selectedCategory == 'all')
          ? null
          : _selectedCategory;

  Future<void> _loadAllData() async {
    await Future.wait([
      context.read<TransactionProvider>().loadAllTransactions(
            category:   _apiCategory,
            type:       _selectedTransactionType,
            status:     _selectedStatus,
            datePreset: _selectedDatePreset,
            search:     _searchController.text.isNotEmpty ? _searchController.text : null,
            startDate:  _selectedDateRange?.start.toIso8601String(),
            endDate:    _selectedDateRange?.end.toIso8601String(),
            locationId: _selectedLocationId,
            managerId:  _selectedManagerId,
            itemId:     _selectedItemId,
          ),
      context.read<LocationProvider>().loadLocations(),
      context.read<ManagerProvider>().fetchManagers(),
    ]);
  }

  void _scrollListener() {
    final pos = _scrollController.position;
    if (pos.maxScrollExtent > 0 && pos.pixels >= pos.maxScrollExtent - 200) {
      final transProv = context.read<TransactionProvider>();
      if (transProv.hasMore && !transProv.isLoading) {
        transProv.loadMoreTransactions();
      }
    }
  }

  /// Sends all active filters to the server and reloads the list.
  void _applyFilters() {
    context.read<TransactionProvider>().loadAllTransactions(
          category:   _apiCategory,
          type:       _selectedTransactionType,
          status:     _selectedStatus,
          datePreset: _selectedDatePreset,
          search:     _searchController.text.isNotEmpty ? _searchController.text : null,
          startDate:  _selectedDateRange?.start.toIso8601String(),
          endDate:    _selectedDateRange?.end != null
              ? _selectedDateRange!.end
                  .add(const Duration(hours: 23, minutes: 59, seconds: 59))
                  .toIso8601String()
              : null,
          locationId: _selectedLocationId,
          managerId:  _selectedManagerId,
          itemId:     _selectedItemId,
        );
  }

  int get _activeFilterCount {
    int count = 0;
    if (_selectedStatus != null)      count++;
    if (_selectedDatePreset != null)  count++;
    if (_selectedDateRange != null)   count++;
    if (_selectedLocationId != null)  count++;
    if (_selectedManagerId != null)   count++;
    if (_selectedItemId != null)      count++;
    return count;
  }

  void _clearAllFilters() {
    setState(() {
      _selectedTransactionType = null;
      _selectedStatus          = null;
      _selectedDatePreset      = null;
      _selectedDateRange       = null;
      _selectedLocationId      = null;
      _selectedManagerId       = null;
      _selectedItemId          = null;
      _searchController.clear();
    });
    _applyFilters();
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _selectedDateRange,
      builder: (context, child) => Theme(
        data: ThemeData.light().copyWith(
          primaryColor: Colors.blue.shade800,
          colorScheme: ColorScheme.light(primary: Colors.blue.shade800),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _selectedDateRange = picked);
      _applyFilters();
    }
  }

  // ─── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(_selectedCategory == null
            ? 'Transactions'
            : _categoryOptions
                .firstWhere((c) => c['id'] == _selectedCategory)['label']),
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
              builder: (_, transProv, __) {
                if (transProv.isLoading) {
                  return const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    ),
                  );
                }
                return IconButton(
                  icon: const Icon(Icons.picture_as_pdf),
                  tooltip: 'Export PDF',
                  onPressed: () async {
                    await transProv.exportTransactionsToPdf();
                    if (transProv.errorMessage.isNotEmpty && context.mounted) {
                      AppSnackBar.showError(context, transProv.errorMessage);
                      transProv.clearError();
                    }
                  },
                );
              },
            ),
          // Filter count badge
          if (_selectedCategory != null && _activeFilterCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Stack(
                alignment: Alignment.topRight,
                children: [
                  IconButton(
                    icon: const Icon(Icons.filter_list),
                    tooltip: 'Active filters',
                    onPressed: _clearAllFilters,
                  ),
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: Colors.orange,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$_activeFilterCount',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
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

  // ─── Category grid ────────────────────────────────────────────────────────

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
        final cat = _categoryOptions[index];
        return Card(
          elevation: 4,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: InkWell(
            onTap: () {
              setState(() => _selectedCategory = cat['id']);
              _applyFilters();
            },
            borderRadius: BorderRadius.circular(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(cat['icon'], size: 48, color: cat['color']),
                const SizedBox(height: 12),
                Text(
                  cat['label'],
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─── Transaction list ─────────────────────────────────────────────────────

  Widget _buildTransactionList() {
    return Consumer3<TransactionProvider, LocationProvider, ManagerProvider>(
      builder: (context, transProv, locProv, mgrProv, _) {
        if (transProv.errorMessage.isNotEmpty &&
            transProv.allTransactions.isEmpty) {
          return Column(
            children: [
              _buildAdvancedFilterBar(locProv.locations, mgrProv.managers),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 56, color: Colors.red),
                      const SizedBox(height: 12),
                      Text(transProv.errorMessage,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _loadAllData,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }

        final transactions = transProv.allTransactions;

        return Column(
          children: [
            _buildAdvancedFilterBar(locProv.locations, mgrProv.managers),
            const Divider(height: 1),
            Expanded(
              child: transactions.isEmpty && !transProv.isLoading
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: _loadAllData,
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(12),
                        itemCount: transactions.length + 1,
                        itemBuilder: (context, index) {
                          if (index == transactions.length) {
                            return _buildLoadMoreIndicator(transProv);
                          }
                          return _buildTransactionCard(
                              transactions[index], locProv, mgrProv);
                        },
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.receipt_long_outlined, size: 72, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No transactions found',
            style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500),
          ),
          if (_activeFilterCount > 0) ...[
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: _clearAllFilters,
              icon: const Icon(Icons.clear),
              label: const Text('Clear filters'),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Advanced filter bar ──────────────────────────────────────────────────

  Widget _buildAdvancedFilterBar(
      List<Location> locations, List<Manager> managers) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search items or notes...',
              prefixIcon: const Icon(Icons.search),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
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
            onChanged: (v) {
              if (v.isEmpty) _applyFilters();
            },
          ),
          const SizedBox(height: 10),

          // Scrollable chip row — all server-side filters
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Date preset
                _dropdownChip(
                  label: 'Date',
                  value: _selectedDatePreset,
                  hint: 'Date Preset',
                  items: const ['day', 'week', 'month', 'year'],
                  itemLabel: (v) => v.toUpperCase(),
                  onChanged: (val) {
                    setState(() {
                      _selectedDatePreset = val;
                      if (val != null) _selectedDateRange = null;
                    });
                    _applyFilters();
                  },
                ),
                const SizedBox(width: 8),

                // Status
                _dropdownChip(
                  label: 'Status',
                  value: _selectedStatus,
                  hint: 'Status',
                  items: const ['pending', 'approved', 'rejected'],
                  itemLabel: (v) => v.toUpperCase(),
                  onChanged: (val) {
                    setState(() => _selectedStatus = val);
                    _applyFilters();
                  },
                ),
                const SizedBox(width: 8),

                // Location filter — server-side
                _dropdownChipDynamic<Location>(
                  hint: 'Location',
                  value: _selectedLocationId,
                  items: locations,
                  itemId: (l) => l.id,
                  itemLabel: (l) => l.name,
                  icon: Icons.location_on_outlined,
                  color: Colors.teal,
                  onChanged: (val) {
                    setState(() => _selectedLocationId = val);
                    _applyFilters();
                  },
                ),
                const SizedBox(width: 8),

                // Manager filter — server-side
                _dropdownChipDynamic<Manager>(
                  hint: 'Manager',
                  value: _selectedManagerId,
                  items: managers.where((m) => m.isActive).toList(),
                  itemId: (m) => m.id,
                  itemLabel: (m) => m.name,
                  icon: Icons.manage_accounts_outlined,
                  color: Colors.purple,
                  onChanged: (val) {
                    setState(() => _selectedManagerId = val);
                    _applyFilters();
                  },
                ),
                const SizedBox(width: 8),

                // Item filter — server-side (built from loaded transactions)
                _buildItemFilterChip(),
                const SizedBox(width: 8),

                // Custom date range (hidden when preset chosen)
                if (_selectedDatePreset == null)
                  InputChip(
                    avatar: const Icon(Icons.calendar_today, size: 16),
                    label: Text(
                      _selectedDateRange == null
                          ? 'Custom Date'
                          : '${DateFormat('MMM d').format(_selectedDateRange!.start)} – ${DateFormat('MMM d').format(_selectedDateRange!.end)}',
                    ),
                    selected: _selectedDateRange != null,
                    onPressed: _selectDateRange,
                    onDeleted: _selectedDateRange != null
                        ? () {
                            setState(() => _selectedDateRange = null);
                            _applyFilters();
                          }
                        : null,
                  ),

                // Clear all button when any filter active
                if (_activeFilterCount > 0) ...[
                  const SizedBox(width: 8),
                  ActionChip(
                    avatar: const Icon(Icons.close, size: 14),
                    label: const Text('Clear all'),
                    backgroundColor: Colors.red.shade50,
                    labelStyle: TextStyle(color: Colors.red.shade700),
                    onPressed: _clearAllFilters,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Item filter chip — built from unique items in the currently loaded list.
  Widget _buildItemFilterChip() {
    return Consumer<TransactionProvider>(
      builder: (_, transProv, __) {
        final seen = <String>{};
        final items = <({String id, String name})>[];
        for (final tx in transProv.allTransactions) {
          if (tx.itemId != null && seen.add(tx.itemId!)) {
            items.add((id: tx.itemId!, name: tx.itemName));
          }
        }
        items.sort((a, b) => a.name.compareTo(b.name));

        return _dropdownChipDynamic<({String id, String name})>(
          hint: 'Item',
          value: _selectedItemId,
          items: items,
          itemId: (i) => i.id,
          itemLabel: (i) => i.name,
          icon: Icons.inventory_2_outlined,
          color: Colors.indigo,
          onChanged: (val) {
            setState(() => _selectedItemId = val);
            _applyFilters();
          },
        );
      },
    );
  }

  /// Dropdown chip for simple string lists.
  Widget _dropdownChip({
    required String label,
    required String? value,
    required String hint,
    required List<String> items,
    required String Function(String) itemLabel,
    required void Function(String?) onChanged,
  }) {
    final active = value != null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: active ? Colors.blue.shade100 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: active ? Colors.blue.shade400 : Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(hint, style: const TextStyle(fontSize: 13)),
          isDense: true,
          items: [
            DropdownMenuItem(
                value: null,
                child: Text('All $hint', style: const TextStyle(fontSize: 13))),
            ...items.map((e) => DropdownMenuItem(
                value: e,
                child:
                    Text(itemLabel(e), style: const TextStyle(fontSize: 13)))),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }

  /// Dropdown chip for typed model lists.
  Widget _dropdownChipDynamic<T>({
    required String hint,
    required String? value,
    required List<T> items,
    required String Function(T) itemId,
    required String Function(T) itemLabel,
    required IconData icon,
    required Color color,
    required void Function(String?) onChanged,
  }) {
    final active = value != null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      constraints: const BoxConstraints(maxWidth: 190),
      decoration: BoxDecoration(
        color: active ? color.withValues(alpha: 0.12) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: active ? color : Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(hint, style: const TextStyle(fontSize: 13)),
            ],
          ),
          isDense: true,
          isExpanded: true,
          selectedItemBuilder: (context) => [
            Row(children: [
              Icon(icon, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Flexible(
                child: Text('All $hint',
                    style: const TextStyle(fontSize: 13),
                    overflow: TextOverflow.ellipsis),
              ),
            ]),
            ...items.map((item) => Row(children: [
                  Icon(icon, size: 14, color: color),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      itemLabel(item),
                      style: TextStyle(
                          fontSize: 13,
                          color: color,
                          fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ])),
          ],
          items: [
            DropdownMenuItem<String>(
              value: null,
              child: Text('All $hint', style: const TextStyle(fontSize: 13)),
            ),
            ...items.map((item) => DropdownMenuItem<String>(
                  value: itemId(item),
                  child: Text(
                    itemLabel(item),
                    style: const TextStyle(fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                )),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }

  // ─── Load more ────────────────────────────────────────────────────────────

  Widget _buildLoadMoreIndicator(TransactionProvider transProv) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: transProv.isLoading
            ? const CircularProgressIndicator()
            : transProv.hasMore
                ? OutlinedButton(
                    onPressed: transProv.loadMoreTransactions,
                    child: const Text('Load More'),
                  )
                : Text('All transactions loaded',
                    style:
                        TextStyle(color: Colors.grey[500], fontSize: 13)),
      ),
    );
  }

  // ─── Transaction card ─────────────────────────────────────────────────────

  Widget _buildTransactionCard(
      Transaction tx, LocationProvider locProv, ManagerProvider mgrProv) {
    String locName(String? id) {
      if (id == null) return '';
      return locProv.getLocationById(id)?.name ?? '';
    }

    final locationLine = tx.locationDisplay.isNotEmpty
        ? tx.locationDisplay
        : tx.fromLocation ?? locName(tx.fromLocationId);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showTransactionDetail(tx, locProv, mgrProv),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 52,
                decoration: BoxDecoration(
                  color: _getTypeColor(tx.type),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _typeChip(tx.type, tx.displayType),
                        const SizedBox(width: 6),
                        _statusChip(tx.status),
                        const Spacer(),
                        Text(
                          DateFormat('MMM d, HH:mm').format(tx.createdAt),
                          style:
                              TextStyle(fontSize: 11, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      tx.itemName,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Qty: ${tx.quantity}  ·  $locationLine',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Full detail bottom sheet ─────────────────────────────────────────────

  void _showTransactionDetail(
      Transaction tx, LocationProvider locProv, ManagerProvider mgrProv) {
    String locName(String? id) {
      if (id == null) return '';
      return locProv.getLocationById(id)?.name ?? '';
    }

    final fromLocName = tx.fromLocation ?? locName(tx.fromLocationId);
    final toLocName = tx.toLocation ?? locName(tx.toLocationId);
    final managerName = tx.managerId != null
        ? mgrProv.managers
            .where((m) => m.id == tx.managerId)
            .firstOrNull
            ?.name
        : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (_, scrollCtrl) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 10, bottom: 4),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Row(
                  children: [
                    _typeChip(tx.type, tx.displayType),
                    const SizedBox(width: 8),
                    _statusChip(tx.status),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.all(16),
                  children: [
                    _sectionHeader('Item'),
                    _detailRow(Icons.inventory_2_outlined, 'Name', tx.itemName),
                    if (tx.itemSku != null)
                      _detailRow(Icons.tag, 'SKU', tx.itemSku!),
                    if (tx.itemModelNumber?.isNotEmpty == true)
                      _detailRow(
                          Icons.computer_outlined, 'Model', tx.itemModelNumber!),
                    if (tx.itemSerialNumber?.isNotEmpty == true)
                      _detailRow(
                          Icons.pin_outlined, 'Item Serial', tx.itemSerialNumber!),
                    if (tx.itemPurchaseDate?.isNotEmpty == true)
                      _detailRow(Icons.calendar_today_outlined, 'Purchased',
                          _formatItemDate(tx.itemPurchaseDate!)),
                    if (tx.itemUnit?.isNotEmpty == true)
                      _detailRow(Icons.scale_outlined, 'Unit', tx.itemUnit!),
                    _detailRow(
                        Icons.numbers_outlined, 'Quantity', '${tx.quantity}'),
                    const SizedBox(height: 16),

                    _sectionHeader('Location'),
                    if (tx.type == 'TRANSFER') ...[
                      _detailRow(Icons.output_outlined, 'From',
                          fromLocName.isNotEmpty ? fromLocName : '—'),
                      _detailRow(Icons.input_outlined, 'To',
                          toLocName.isNotEmpty ? toLocName : '—'),
                    ] else if (tx.type == 'ADD') ...[
                      _detailRow(
                          Icons.location_on_outlined,
                          'Location',
                          (toLocName.isNotEmpty ? toLocName : fromLocName)
                                  .isNotEmpty
                              ? (toLocName.isNotEmpty ? toLocName : fromLocName)
                              : '—'),
                    ] else ...[
                      if (fromLocName.isNotEmpty)
                        _detailRow(
                            Icons.location_on_outlined, 'From', fromLocName),
                      if (toLocName.isNotEmpty)
                        _detailRow(Icons.location_on_outlined, 'To', toLocName),
                    ],
                    const SizedBox(height: 16),

                    if (tx.vendorName?.isNotEmpty == true ||
                        tx.serialNumber?.isNotEmpty == true ||
                        tx.reason?.isNotEmpty == true ||
                        tx.note?.isNotEmpty == true) ...[
                      _sectionHeader('Details'),
                      if (tx.vendorName?.isNotEmpty == true)
                        _detailRow(
                            Icons.business_outlined, 'Vendor', tx.vendorName!),
                      if (tx.serialNumber?.isNotEmpty == true)
                        _detailRow(
                            Icons.pin_outlined, 'Serial No', tx.serialNumber!),
                      if (tx.reason?.isNotEmpty == true)
                        _detailRow(
                            Icons.help_outline, 'Reason', tx.reason!),
                      if (tx.note?.isNotEmpty == true)
                        _detailRow(
                            Icons.note_alt_outlined, 'Note', tx.note!),
                      const SizedBox(height: 16),
                    ],

                    _sectionHeader('Audit'),
                    _detailRow(Icons.schedule, 'Created', _formatDate(tx.createdAt)),
                    if (tx.createdByName?.isNotEmpty == true)
                      _detailRow(
                          Icons.person_outline,
                          'Created By',
                          tx.createdByEmail?.isNotEmpty == true
                              ? '${tx.createdByName!} (${tx.createdByEmail!})'
                              : tx.createdByName!),
                    if (managerName?.isNotEmpty == true)
                      _detailRow(Icons.manage_accounts_outlined, 'Manager',
                          managerName!),
                    if (tx.approvedByName?.isNotEmpty == true)
                      _detailRow(Icons.verified_user_outlined, 'Approved By',
                          tx.approvedByName!),
                    if (tx.approvedAt != null)
                      _detailRow(Icons.calendar_month_outlined, 'Approved At',
                          _formatDate(tx.approvedAt!)),
                    const SizedBox(height: 16),

                    if (tx.photo?.isNotEmpty == true) ...[
                      _sectionHeader('Attachment'),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () =>
                            _showFullScreenImage(context, tx.photo!),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: _buildImageFromBase64(tx.photo!),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    if (tx.repairReturnChecklist.isNotEmpty) ...[
                      _sectionHeader('Repair Checklist'),
                      const SizedBox(height: 4),
                      ...tx.repairReturnChecklist.map((item) =>
                          CheckboxListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            value: item.completed,
                            onChanged: null,
                            title: Text(
                              item.label,
                              style: TextStyle(
                                fontSize: 14,
                                decoration: item.completed
                                    ? TextDecoration.lineThrough
                                    : null,
                                color: item.completed
                                    ? Colors.grey
                                    : Colors.black87,
                              ),
                            ),
                            controlAffinity: ListTileControlAffinity.leading,
                          )),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Colors.grey[500],
            letterSpacing: 1.1,
          ),
        ),
      );

  Widget _typeChip(String type, String label) {
    final color = _getTypeColor(type);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }

  Widget _statusChip(String status) {
    final color = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(status.toUpperCase(),
          style: TextStyle(
              color: color, fontSize: 10, fontWeight: FontWeight.w600)),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  Widget _detailRow(IconData icon, String label, String value) {
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
            child: Text(label,
                style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[800],
                    fontSize: 13)),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  Widget _buildImageFromBase64(String b64) {
    try {
      final clean = b64.contains(',') ? b64.split(',').last : b64;
      return Image.memory(base64Decode(clean), fit: BoxFit.cover);
    } catch (_) {
      return const Center(
          child: Icon(Icons.broken_image, color: Colors.grey));
    }
  }

  void _showFullScreenImage(BuildContext context, String b64) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: _buildImageFromBase64(b64)),
            Padding(
              padding: const EdgeInsets.all(8),
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
      case 'ADD':        return Colors.green;
      case 'TRANSFER':   return Colors.blue;
      case 'REPAIR_OUT': return Colors.purple;
      case 'REPAIR_IN':  return Colors.indigo;
      case 'DISPOSE':    return Colors.red;
      default:           return Colors.grey;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved': return Colors.green;
      case 'pending':  return Colors.orange;
      case 'rejected': return Colors.red;
      default:         return Colors.blueGrey;
    }
  }

  String _formatDate(DateTime dt) =>
      DateFormat('MMM dd, yyyy HH:mm').format(dt);

  String _formatItemDate(String raw) {
    try {
      return DateFormat('MMM dd, yyyy').format(DateTime.parse(raw));
    } catch (_) {
      return raw;
    }
  }
}
