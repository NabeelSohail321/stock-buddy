import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stock_buddy/profile/profile_screen.dart';
import 'package:stock_buddy/screens/items/items_screen.dart';
import 'package:stock_buddy/screens/repair/return_from_repair_screen.dart';
import 'package:stock_buddy/screens/repair/send_to_repair_screen.dart';
import 'package:stock_buddy/screens/stock/add_stock_screen.dart';
import 'package:stock_buddy/screens/stock/low_stock_screen.dart';
import 'package:stock_buddy/screens/stock/pending_transfers_screen.dart';
import 'package:stock_buddy/screens/stock/stock_management_screen.dart';
import 'package:stock_buddy/screens/stock/transfer_stock_screen.dart';
import 'package:stock_buddy/screens/transactions/transactions_screen.dart';
import 'package:stock_buddy/providers/transaction_provider.dart';
import 'package:stock_buddy/models/transaction_model.dart';
import 'package:stock_buddy/services/local_storage_service.dart';
import 'package:stock_buddy/models/user_model.dart';

import 'disposal/disposal_request_screen.dart';
import 'disposal/pending_disposals_screen.dart';
import 'items/create_item_screen.dart';
import 'items/item_management_screen.dart';
import 'users/user_management_screen.dart';
import 'location/location_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  User? _currentUser;
  bool _isLoadingUser = true;
  bool _isRefreshingTransactions = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRecentTransactions();
    });
  }

  Future<void> _loadCurrentUser() async {
    try {
      final localStorageService = LocalStorageService();
      final user = await localStorageService.getUser();
      setState(() {
        _currentUser = user;
        _isLoadingUser = false;
      });
    } catch (e) {
      print('Error loading user: $e');
      setState(() {
        _isLoadingUser = false;
      });
    }
  }

  Future<void> _loadRecentTransactions() async {
    if (!_isAdmin) return;

    setState(() {
      _isRefreshingTransactions = true;
    });

    final transactionProvider = context.read<TransactionProvider>();
    await transactionProvider.loadRecentTransactions();

    setState(() {
      _isRefreshingTransactions = false;
    });
  }

  void _handleQuickAction(String action) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$action action clicked!'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _navigateToTransactions() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const TransactionsScreen(),
      ),
    );
  }

  bool get _isAdmin {
    return _currentUser?.role == 'admin';
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh transactions when returning to this screen
    if (_isAdmin && !_isRefreshingTransactions) {
      _loadRecentTransactions();
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width >= 1200;
    final isTablet = size.width >= 768 && size.width < 1200;
    final isMobile = size.width < 768;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 32 : isTablet ? 24 : 16,
            vertical: 16,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: size.height - MediaQuery.of(context).padding.vertical,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                _buildHeader(isDesktop, isTablet, isMobile),
                const SizedBox(height: 24),

                // Admin Badge
                if (_isAdmin) _buildAdminBadge(isDesktop, isTablet, isMobile),
                if (_isAdmin) const SizedBox(height: 16),

                // Quick Actions Section
                _buildQuickActionsSection(isDesktop, isTablet, isMobile),
                const SizedBox(height: 32),

                // Recent Transactions Section - Only for Admin
                if (_isAdmin) _buildTransactionsSection(isDesktop, isTablet, isMobile),
                if (_isAdmin) const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDesktop, bool isTablet, bool isMobile) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome back!',
                style: TextStyle(
                  fontSize: isDesktop ? 28 : isTablet ? 26 : 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                  fontFamily: 'Roboto',
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Manage your inventory efficiently',
                style: TextStyle(
                  fontSize: isDesktop ? 16 : isTablet ? 15 : 14,
                  color: Colors.grey[600],
                  fontFamily: 'Roboto',
                ),
              ),
              if (_currentUser != null) ...[
                const SizedBox(height: 4),
                Text(
                  '${_currentUser!.name} (${_currentUser!.role.toUpperCase()})',
                  style: TextStyle(
                    fontSize: isDesktop ? 14 : isTablet ? 13 : 12,
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Roboto',
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 16),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ProfileScreen(),
              ),
            );
          },
          child: Container(
            padding: EdgeInsets.all(isDesktop ? 14 : isTablet ? 13 : 12),
            decoration: BoxDecoration(
              color: Colors.blue.shade800,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.person,
              color: Colors.white,
              size: isDesktop ? 28 : isTablet ? 26 : 24,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAdminBadge(bool isDesktop, bool isTablet, bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 20 : isTablet ? 18 : 16,
        vertical: isDesktop ? 10 : isTablet ? 9 : 8,
      ),
      decoration: BoxDecoration(
        color: Colors.purple.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.purple.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.security_rounded,
            color: Colors.purple.shade700,
            size: isDesktop ? 18 : isTablet ? 17 : 16,
          ),
          SizedBox(width: isDesktop ? 10 : isTablet ? 9 : 8),
          Text(
            'Administrator Access',
            style: TextStyle(
              color: Colors.purple.shade700,
              fontWeight: FontWeight.w600,
              fontSize: isDesktop ? 15 : isTablet ? 14 : 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsSection(bool isDesktop, bool isTablet, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: isDesktop ? 22 : isTablet ? 20 : 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
            fontFamily: 'Roboto',
          ),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = constraints.maxWidth;
            int crossAxisCount;

            if (maxWidth > 1200) {
              crossAxisCount = 4;
            } else if (maxWidth > 900) {
              crossAxisCount = 3;
            } else if (maxWidth > 600) {
              crossAxisCount = 2;
            } else {
              crossAxisCount = 1;
            }

            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: isDesktop ? 20 : isTablet ? 18 : 16,
              mainAxisSpacing: isDesktop ? 20 : isTablet ? 18 : 16,
              childAspectRatio: _getChildAspectRatio(isDesktop, isTablet, isMobile),
              children: _getQuickActionCards(isDesktop, isTablet, isMobile),
            );
          },
        ),
      ],
    );
  }

  double _getChildAspectRatio(bool isDesktop, bool isTablet, bool isMobile) {
    if (isDesktop) return 1.3;
    if (isTablet) return 1.2;
    return 1.1;
  }

  List<Widget> _getQuickActionCards(bool isDesktop, bool isTablet, bool isMobile) {
    List<QuickActionCard> actions = [
      QuickActionCard(
        icon: Icons.inventory_2_rounded,
        title: 'Stock Management',
        subtitle: 'Manage stock levels and locations',
        color: Colors.blue.shade700,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const StockManagementScreen(),
            ),
          );
        },
      ),
      QuickActionCard(
        icon: Icons.qr_code_scanner_rounded,
        title: 'Item Management',
        subtitle: 'Items that you will manage in your inventory',
        color: Colors.blue.shade700,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ItemManagementScreen(),
            ),
          );
        },
      ),
      QuickActionCard(
        icon: Icons.compare_arrows_rounded,
        title: 'Transfer',
        subtitle: 'Move stock across locations',
        color: Colors.orange.shade700,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const TransferStockScreen(),
            ),
          );
        },
      ),
      QuickActionCard(
        icon: Icons.build_circle_rounded,
        title: 'Send to Repair',
        subtitle: 'Track equipment out for service',
        color: Colors.purple.shade700,
        onTap: () => {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const SendToRepairScreen(),
            ),
          )
        },
      ),
      QuickActionCard(
        icon: Icons.assignment_return_rounded,
        title: 'Return from Repair',
        subtitle: 'Receive repaired items back to stock',
        color: Colors.green.shade700,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ReturnFromRepairScreen(),
            ),
          );
        },
      ),
      QuickActionCard(
        icon: Icons.delete_outline_rounded,
        title: 'Dispose',
        subtitle: 'Throw out broken/obsolete items',
        color: Colors.red.shade700,
        onTap: () => {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const DisposalRequestScreen(),
            ),
          )
        },
      ),
      QuickActionCard(
        icon: Icons.warning_amber_rounded,
        title: 'Low Stock',
        subtitle: 'Items at/below threshold',
        color: Colors.amber.shade700,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const LowStockScreen(),
            ),
          );
        },
      ),
    ];

    // Add admin-specific actions if user is admin
    if (_isAdmin) {
      // Add Location Management for Admin
      actions.insert(4, QuickActionCard(
        icon: Icons.location_on_rounded,
        title: 'Location Management',
        subtitle: 'Manage all warehouse and storage locations',
        color: Colors.indigo.shade700,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const LocationListScreen(),
            ),
          );
        },
      ));

      actions.insert(5, QuickActionCard(
        icon: Icons.assignment_turned_in_rounded,
        title: 'Review Transfers',
        subtitle: 'Approve or reject pending stock transfers',
        color: Colors.teal.shade700,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const PendingTransfersScreen(),
            ),
          );
        },
      ));

      actions.insert(6, QuickActionCard(
        icon: Icons.delete_sweep_rounded,
        title: 'Review Disposals',
        subtitle: 'Approve or reject disposal requests',
        color: Colors.orange.shade700,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const PendingDisposalsScreen(),
            ),
          );
        },
      ));

      // Replace Admin Panel with User Management
      actions.insert(7, QuickActionCard(
        icon: Icons.people_alt_rounded,
        title: 'User Management',
        subtitle: 'Manage users and system settings',
        color: Colors.deepPurple.shade700,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const UserManagementScreen(),
            ),
          );
        },
      ));
    }

    return actions.map((action) => _buildEnhancedQuickActionCard(
      icon: action.icon,
      title: action.title,
      subtitle: action.subtitle,
      color: action.color,
      onTap: action.onTap,
      isDesktop: isDesktop,
      isTablet: isTablet,
      isMobile: isMobile,
    )).toList();
  }

  Widget _buildEnhancedQuickActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    required bool isDesktop,
    required bool isTablet,
    required bool isMobile,
  }) {
    final gradient = LinearGradient(
      colors: [color.withOpacity(0.1), color.withOpacity(0.2)],
    );

    final iconSize = isDesktop ? 36 : isTablet ? 32 : 28;
    final titleSize = isDesktop ? 18 : isTablet ? 17 : 16;
    final subtitleSize = isDesktop ? 14 : isTablet ? 13 : 12;
    final padding = isDesktop ? 24.0 : isTablet ? 20.0 : 16.0;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 200),
        tween: Tween(begin: 1.0, end: 1.0),
        builder: (context, scale, child) {
          return Transform.scale(
            scale: scale,
            child: child,
          );
        },
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: color.withOpacity(0.3),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 2,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  top: -10,
                  right: -10,
                  child: Icon(
                    icon,
                    size: isDesktop ? 70 : isTablet ? 60 : 50,
                    color: color.withOpacity(0.1),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(padding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: EdgeInsets.all(isDesktop ? 14 : isTablet ? 12 : 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: color.withOpacity(0.2),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: color.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          icon,
                          color: color,
                          size: iconSize.toDouble(),
                        ),
                      ),
                      SizedBox(height: isDesktop ? 16 : isTablet ? 14 : 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: titleSize.toDouble(),
                              fontWeight: FontWeight.bold,
                              color: color,
                              fontFamily: 'Roboto',
                            ),
                          ),
                          SizedBox(height: isDesktop ? 8 : isTablet ? 7 : 6),
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: subtitleSize.toDouble(),
                              color: Colors.grey[700],
                              fontFamily: 'Roboto',
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                      SizedBox(height: isDesktop ? 12 : isTablet ? 10 : 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isDesktop ? 10 : isTablet ? 9 : 8,
                              vertical: isDesktop ? 6 : isTablet ? 5 : 4,
                            ),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: color.withOpacity(0.3),
                              ),
                            ),
                            child: Icon(
                              Icons.arrow_forward_rounded,
                              size: isDesktop ? 18 : isTablet ? 17 : 16,
                              color: color,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionsSection(bool isDesktop, bool isTablet, bool isMobile) {
    return Consumer<TransactionProvider>(
      builder: (context, transactionProvider, child) {
        // Use demo data if real data fails to load
        final hasRealData = transactionProvider.recentTransactions.isNotEmpty;
        final hasError = transactionProvider.errorMessage.isNotEmpty;

        List<Transaction> displayTransactions = hasRealData
            ? transactionProvider.recentTransactions
            : _getDemoTransactions();

        return Card(
          elevation: 2,
          shadowColor: Colors.black12,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: EdgeInsets.all(isDesktop ? 24 : isTablet ? 20 : 5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent Transactions',
                      style: TextStyle(
                        fontSize: isDesktop ? 22 : isTablet ? 20 : 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                        fontFamily: 'Roboto',
                      ),
                    ),
                    Row(
                      children: [
                        if (_isRefreshingTransactions)
                          Padding(
                            padding: EdgeInsets.only(right: isDesktop ? 12 : isTablet ? 10 : 8),
                            child: SizedBox(
                              width: isDesktop ? 20 : isTablet ? 18 : 16,
                              height: isDesktop ? 20 : isTablet ? 18 : 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        else
                          IconButton(
                            icon: Icon(Icons.refresh,
                                size: isDesktop ? 24 : isTablet ? 22 : 20),
                            onPressed: _loadRecentTransactions,
                            tooltip: 'Refresh Transactions',
                          ),
                        TextButton(
                          onPressed: _navigateToTransactions,
                          child: Text(
                            'View All',
                            style: TextStyle(
                              fontSize: isDesktop ? 16 : isTablet ? 15 : 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: isDesktop ? 20 : isTablet ? 18 : 16),

                if (hasError && !hasRealData)
                  _buildErrorWidget(transactionProvider, isDesktop, isTablet, isMobile),

                if ((transactionProvider.isLoading || _isRefreshingTransactions) && !hasRealData)
                  _buildLoadingWidget(isDesktop, isTablet, isMobile),

                if (!transactionProvider.isLoading && !_isRefreshingTransactions && displayTransactions.isEmpty)
                  _buildEmptyTransactions(isDesktop, isTablet, isMobile),

                if (displayTransactions.isNotEmpty && !_isRefreshingTransactions)
                  _buildTransactionsTable(displayTransactions, isDesktop, isTablet, isMobile, isDemo: !hasRealData),

                if (_isRefreshingTransactions && displayTransactions.isNotEmpty)
                  _buildRefreshingTable(displayTransactions, isDesktop, isTablet, isMobile, isDemo: !hasRealData),
              ],
            ),
          ),
        );
      },
    );
  }

  // Add demo transactions as fallback
  List<Transaction> _getDemoTransactions() {
    return [
      Transaction(
        id: '1',
        type: 'ADD',
        status: 'approved',
        itemName: 'Laptop Dell XPS',
        toLocation: 'Store A',
        quantity: 5,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      Transaction(
        id: '2',
        type: 'TRANSFER',
        status: 'approved',
        itemName: 'iPhone 14',
        fromLocation: 'Store A',
        toLocation: 'Store B',
        quantity: 3,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      Transaction(
        id: '3',
        type: 'DISPOSE',
        status: 'approved',
        itemName: 'Broken Monitor',
        fromLocation: 'Store C',
        quantity: 1,
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
      ),
    ];
  }

  // Update the transactions table to handle demo data
  Widget _buildTransactionsTable(List<Transaction> transactions, bool isDesktop, bool isTablet, bool isMobile, {bool isDemo = false}) {
    // Take only first 10 transactions for home screen
    final displayTransactions = transactions.take(10).toList();

    return Column(
      children: [
        if (isDemo)
          Container(
            padding: EdgeInsets.all(isDesktop ? 12 : isTablet ? 10 : 8),
            margin: EdgeInsets.only(bottom: isDesktop ? 20 : isTablet ? 18 : 16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.orange.shade600,
                    size: isDesktop ? 18 : isTablet ? 17 : 16),
                SizedBox(width: isDesktop ? 10 : isTablet ? 9 : 8),
                Expanded(
                  child: Text(
                    'Showing demo data. Real transactions will appear here once connected.',
                    style: TextStyle(
                      color: Colors.orange.shade600,
                      fontSize: isDesktop ? 14 : isTablet ? 13 : 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        SingleChildScrollView(
          scrollDirection: isMobile ? Axis.horizontal : Axis.vertical,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: isMobile ? 600 : double.infinity,
            ),
            child: DataTable(
              headingTextStyle: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
                fontFamily: 'Roboto',
                fontSize: isDesktop ? 15 : isTablet ? 14 : 13,
              ),
              dataTextStyle: TextStyle(
                fontFamily: 'Roboto',
                fontSize: isDesktop ? 14 : isTablet ? 13 : 12,
              ),
              columns: const [
                DataColumn(label: Text('Time')),
                DataColumn(label: Text('Type')),
                DataColumn(label: Text('Item')),
                DataColumn(label: Text('From → To')),
                DataColumn(label: Text('Qty')),
              ],
              rows: displayTransactions.map((transaction) {
                return DataRow(cells: [
                  DataCell(Text(_formatTime(transaction.createdAt))),
                  DataCell(
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isDesktop ? 10 : isTablet ? 9 : 8,
                        vertical: isDesktop ? 6 : isTablet ? 5 : 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getTypeColor(transaction.type).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        transaction.displayType,
                        style: TextStyle(
                          color: _getTypeColor(transaction.type),
                          fontWeight: FontWeight.w500,
                          fontSize: isDesktop ? 13 : isTablet ? 12 : 11,
                        ),
                      ),
                    ),
                  ),
                  DataCell(
                    Tooltip(
                      message: transaction.displayItem,
                      child: Text(
                        transaction.itemName,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      transaction.fromToDisplay,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  DataCell(Text(transaction.quantity.toString())),
                ]);
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRefreshingTable(List<Transaction> transactions, bool isDesktop, bool isTablet, bool isMobile, {bool isDemo = false}) {
    // Take only first 10 transactions for home screen
    final displayTransactions = transactions.take(10).toList();

    return Opacity(
      opacity: 0.6,
      child: Column(
        children: [
          if (isDemo)
            Container(
              padding: EdgeInsets.all(isDesktop ? 12 : isTablet ? 10 : 8),
              margin: EdgeInsets.only(bottom: isDesktop ? 20 : isTablet ? 18 : 16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange.shade600,
                      size: isDesktop ? 18 : isTablet ? 17 : 16),
                  SizedBox(width: isDesktop ? 10 : isTablet ? 9 : 8),
                  Expanded(
                    child: Text(
                      'Showing demo data. Real transactions will appear here once connected.',
                      style: TextStyle(
                        color: Colors.orange.shade600,
                        fontSize: isDesktop ? 14 : isTablet ? 13 : 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          SingleChildScrollView(
            scrollDirection: isMobile ? Axis.horizontal : Axis.vertical,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: isMobile ? 600 : double.infinity,
              ),
              child: DataTable(
                headingTextStyle: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                  fontFamily: 'Roboto',
                  fontSize: isDesktop ? 15 : isTablet ? 14 : 13,
                ),
                dataTextStyle: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: isDesktop ? 14 : isTablet ? 13 : 12,
                ),
                columns: const [
                  DataColumn(label: Text('Time')),
                  DataColumn(label: Text('Type')),
                  DataColumn(label: Text('Item')),
                  DataColumn(label: Text('From → To')),
                  DataColumn(label: Text('Qty')),
                ],
                rows: displayTransactions.map((transaction) {
                  return DataRow(cells: [
                    DataCell(Text(_formatTime(transaction.createdAt))),
                    DataCell(
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isDesktop ? 10 : isTablet ? 9 : 8,
                          vertical: isDesktop ? 6 : isTablet ? 5 : 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getTypeColor(transaction.type).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          transaction.displayType,
                          style: TextStyle(
                            color: _getTypeColor(transaction.type),
                            fontWeight: FontWeight.w500,
                            fontSize: isDesktop ? 13 : isTablet ? 12 : 11,
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      Tooltip(
                        message: transaction.displayItem,
                        child: Text(
                          transaction.itemName,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        transaction.fromToDisplay,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    DataCell(Text(transaction.quantity.toString())),
                  ]);
                }).toList(),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(isDesktop ? 12 : isTablet ? 10 : 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: isDesktop ? 20 : isTablet ? 18 : 16,
                  height: isDesktop ? 20 : isTablet ? 18 : 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: isDesktop ? 12 : isTablet ? 10 : 8),
                Text(
                  'Refreshing...',
                  style: TextStyle(
                      fontSize: isDesktop ? 14 : isTablet ? 13 : 12,
                      color: Colors.grey
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(TransactionProvider transactionProvider, bool isDesktop, bool isTablet, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isDesktop ? 16 : isTablet ? 14 : 12),
      margin: EdgeInsets.only(bottom: isDesktop ? 20 : isTablet ? 18 : 16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade600,
              size: isDesktop ? 24 : isTablet ? 22 : 20),
          SizedBox(width: isDesktop ? 12 : isTablet ? 10 : 8),
          Expanded(
            child: Text(
              transactionProvider.errorMessage,
              style: TextStyle(
                color: Colors.red.shade600,
                fontSize: isDesktop ? 14 : isTablet ? 13 : 12,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, color: Colors.red.shade600,
                size: isDesktop ? 24 : isTablet ? 22 : 20),
            onPressed: () => transactionProvider.clearError(),
          ),
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.red.shade600,
                size: isDesktop ? 24 : isTablet ? 22 : 20),
            onPressed: _loadRecentTransactions,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingWidget(bool isDesktop, bool isTablet, bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: isDesktop ? 50 : isTablet ? 45 : 40),
      child: Center(
        child: Column(
          children: [
            CircularProgressIndicator(),
            SizedBox(height: isDesktop ? 20 : isTablet ? 18 : 16),
            Text(
              'Loading transactions...',
              style: TextStyle(
                fontSize: isDesktop ? 16 : isTablet ? 15 : 14,
                fontFamily: 'Roboto',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyTransactions(bool isDesktop, bool isTablet, bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: isDesktop ? 50 : isTablet ? 45 : 40),
      child: Column(
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: isDesktop ? 80 : isTablet ? 72 : 64,
            color: Colors.grey[400],
          ),
          SizedBox(height: isDesktop ? 20 : isTablet ? 18 : 16),
          Text(
            'No transactions yet',
            style: TextStyle(
              fontSize: isDesktop ? 18 : isTablet ? 17 : 16,
              color: Colors.grey[600],
              fontFamily: 'Roboto',
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: isDesktop ? 12 : isTablet ? 11 : 8),
          OutlinedButton.icon(
            onPressed: _loadRecentTransactions,
            icon: Icon(Icons.refresh,
                size: isDesktop ? 18 : isTablet ? 17 : 16),
            label: Text(
              'Refresh',
              style: TextStyle(
                fontSize: isDesktop ? 15 : isTablet ? 14 : 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'ADD':
        return Colors.green;
      case 'TRANSFER':
        return Colors.orange;
      case 'REPAIR_OUT':
        return Colors.purple;
      case 'REPAIR_IN':
        return Colors.blue;
      case 'DISPOSE':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
      final minute = date.minute.toString().padLeft(2, '0');
      final period = date.hour < 12 ? 'AM' : 'PM';
      return '$hour:$minute $period';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

class QuickActionCard {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });
}