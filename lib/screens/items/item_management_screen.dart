import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:stock_buddy/models/item_model.dart';
import 'package:stock_buddy/providers/auth_provider.dart';
import 'package:stock_buddy/providers/items_provider.dart';
import 'package:stock_buddy/screens/items/create_item_screen.dart';
import 'package:stock_buddy/screens/items/items_screen.dart';
import 'package:stock_buddy/screens/items/edit_item_screen.dart';
import 'package:stock_buddy/screens/items/barcode_scanner_screen.dart';

class ItemManagementScreen extends StatefulWidget {
  const ItemManagementScreen({super.key});

  @override
  State<ItemManagementScreen> createState() => _ItemManagementScreenState();
}

class _ItemManagementScreenState extends State<ItemManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _barcodeController = TextEditingController();
  bool _isSearching = false;
  String _barcodeError = '';
  bool _initialLoadCompleted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadItems();
    });
  }

  Future<void> _loadItems() async {
    final itemsProvider = context.read<ItemsProvider>();
    await itemsProvider.fetchItems();
    if (mounted) {
      setState(() {
        _initialLoadCompleted = true;
      });
    }
  }

  void _handleSearch(String query) {
    final itemsProvider = context.read<ItemsProvider>();
    if (query.isEmpty) {
      itemsProvider.clearSearch();
    } else {
      itemsProvider.searchItemsApi(query);
    }
  }

  Future<void> _lookupBarcode() async {
    final barcode = _barcodeController.text.trim();
    if (barcode.isEmpty) {
      setState(() {
        _barcodeError = 'Please enter a barcode';
      });
      return;
    }

    setState(() {
      _barcodeError = '';
    });

    final itemsProvider = context.read<ItemsProvider>();
    final item = await itemsProvider.getItemByBarcode(barcode);

    if (item != null && mounted) {
      _barcodeController.clear();
      _showItemFoundDialog(item);
    } else if (mounted) {
      setState(() {
        _barcodeError = 'Item not found for barcode: $barcode';
      });
    }
  }

  void _showItemFoundDialog(Item item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Item Found'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Name: ${item.name}', style: const TextStyle(fontWeight: FontWeight.bold)),
            if (item.sku != null && item.sku!.isNotEmpty) Text('SKU: ${item.sku}'),
            if (item.barcode != null && item.barcode!.isNotEmpty) Text('Barcode: ${item.barcode}'),
            Text('Unit: ${item.unit ?? "N/A"}'),
            Text('Threshold: ${item.threshold ?? 0}'),
            const SizedBox(height: 16),
            Text(
              'Status: ${item.effectiveStatus}',
              style: TextStyle(
                color: item.isActive ? Colors.green : Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _navigateToEditItem(item);
            },
            child: const Text('Edit Item'),
          ),
          if (item.barcode != null && item.barcode!.isNotEmpty)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _printBarcode(item);
              },
              child: const Text('Print Barcode'),
            ),
        ],
      ),
    );
  }

  void _navigateToEditItem(Item item) async {
    // Navigate to edit screen and wait for result
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditItemScreen(item: item),
      ),
    );

    // Refresh items when returning from edit screen only if changes were made
    if (result == true && mounted) {
      await _loadItems();
    }
  }

  void _navigateToBarcodeScanner() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const BarcodeScannerScreen(),
      ),
    );

    if (result != null && mounted) {
      _barcodeController.text = result;
      _lookupBarcode();
    }
  }

  // Barcode printing function
  Future<void> _printBarcode(Item item) async {
    try {
      final pdf = pw.Document();

      // Create barcode page
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat(86, 54), // Standard barcode label size
          build: (pw.Context context) {
            return pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                // Item name
                pw.Text(
                  item.name,
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  textAlign: pw.TextAlign.center,
                  maxLines: 2,
                ),
                pw.SizedBox(height: 4),

                // Barcode number
                pw.Text(
                  item.barcode!,
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
                pw.SizedBox(height: 8),

                // Barcode representation (simulated with lines)
                _buildBarcodeVisual(item.barcode!),
                pw.SizedBox(height: 4),

                // Additional info
                if (item.sku != null && item.sku!.isNotEmpty)
                  pw.Text(
                    'SKU: ${item.sku}',
                    style: pw.TextStyle(fontSize: 8),
                    textAlign: pw.TextAlign.center,
                  ),
                pw.Text(
                  'Unit: ${item.unit ?? "N/A"}',
                  style: pw.TextStyle(fontSize: 8),
                  textAlign: pw.TextAlign.center,
                ),
              ],
            );
          },
        ),
      );

      // Print or share the PDF
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Barcode sent to printer'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to print barcode: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Build visual barcode representation
  pw.Widget _buildBarcodeVisual(String barcode) {
    // Simple barcode visualization using alternating bars
    // This is a simplified representation - for real barcodes, use a barcode library
    final bars = <pw.Widget>[];

    for (int i = 0; i < barcode.length; i++) {
      final digit = barcode[i];
      final barHeight = 20.0;
      final barWidth = 2.0;

      // Alternate between black and white bars based on digit value
      final isBlack = int.tryParse(digit) != null ? int.parse(digit) % 2 == 0 : i % 2 == 0;

      bars.add(
        pw.Container(
          width: barWidth,
          height: barHeight,
          color: isBlack ? PdfColors.black : PdfColors.white,
        ),
      );

      // Add small gap between bars
      if (i < barcode.length - 1) {
        bars.add(pw.SizedBox(width: 1));
      }
    }

    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 1),
      ),
      padding: const pw.EdgeInsets.all(4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        children: bars,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final itemsProvider = context.watch<ItemsProvider>();
    final isAdmin = authProvider.currentUser?.role == 'admin';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Item Management'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        actions: [
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreateItemScreen(),
                  ),
                );
                // Refresh items after creating new item
                if (mounted) {
                  await _loadItems();
                }
              },
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadItems,
            tooltip: 'Refresh Items',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Barcode Section
          _buildSearchSection(itemsProvider),

          // Items List
          Expanded(
            child: _buildItemsList(itemsProvider, isAdmin),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSection(ItemsProvider itemsProvider) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Search Bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Search Items',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  _handleSearch('');
                },
              )
                  : null,
              border: const OutlineInputBorder(),
            ),
            onChanged: _handleSearch,
          ),
          const SizedBox(height: 16),

          // Barcode Lookup Section
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Barcode Lookup',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _barcodeController,
                          decoration: InputDecoration(
                            labelText: 'Enter Barcode',
                            errorText: _barcodeError.isEmpty ? null : _barcodeError,
                            border: const OutlineInputBorder(),
                          ),
                          onSubmitted: (_) => _lookupBarcode(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.qr_code_scanner),
                        onPressed: _navigateToBarcodeScanner,
                        tooltip: 'Scan Barcode',
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _lookupBarcode,
                        child: const Text('Lookup'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsList(ItemsProvider itemsProvider, bool isAdmin) {
    // Show loading only on initial load
    if (!_initialLoadCompleted && itemsProvider.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading items...'),
          ],
        ),
      );
    }

    if (itemsProvider.errorMessage.isNotEmpty && itemsProvider.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Error loading items',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              itemsProvider.errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadItems,
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    if (itemsProvider.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No Items Found',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            const Text(
              'Get started by creating your first item',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreateItemScreen(),
                  ),
                );
                // Refresh items after creating new item
                if (mounted) {
                  await _loadItems();
                }
              },
              child: const Text('Create First Item'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Items count
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              Text(
                '${itemsProvider.items.length} item${itemsProvider.items.length != 1 ? 's' : ''}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
              const Spacer(),
              if (itemsProvider.isLoading)
                const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Items list
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadItems,
            child: ListView.builder(
              itemCount: itemsProvider.items.length,
              itemBuilder: (context, index) {
                final item = itemsProvider.items[index];
                return _buildItemCard(item, itemsProvider, isAdmin);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildItemCard(Item item, ItemsProvider itemsProvider, bool isAdmin) {
    final displayStatus = item.isActive ? 'active' : 'inactive';
    final barcode = item.barcode ?? '';
    final sku = item.sku ?? '';
    final unit = item.unit ?? 'N/A';
    final threshold = item.threshold ?? 0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: item.isActive ? Colors.green : Colors.orange,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.inventory_2,
            color: Colors.white,
            size: 24,
          ),
        ),
        title: Text(
          item.name,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            decoration: !item.isActive ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (sku.isNotEmpty) Text('SKU: $sku'),
            if (barcode.isNotEmpty) Text('Barcode: $barcode'),
            Text('Unit: $unit • Threshold: $threshold'),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: item.isActive ? Colors.green[50] : Colors.orange[50],
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: item.isActive ? Colors.green : Colors.orange,
                ),
              ),
              child: Text(
                displayStatus.toUpperCase(),
                style: TextStyle(
                  color: item.isActive ? Colors.green : Colors.orange,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        trailing: isAdmin
            ? PopupMenuButton<String>(
          onSelected: (value) => _handleItemAction(value, item, itemsProvider),
          itemBuilder: (context) {
            final menuItems = <PopupMenuEntry<String>>[
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 20),
                    SizedBox(width: 8),
                    Text('Edit'),
                  ],
                ),
              ),
            ];

            // Always show barcode options, but with different labels
            if (barcode.isEmpty) {
              menuItems.add(
                const PopupMenuItem(
                  value: 'generate_barcode',
                  child: Row(
                    children: [
                      Icon(Icons.qr_code, size: 20),
                      SizedBox(width: 8),
                      Text('Generate Barcode'),
                    ],
                  ),
                ),
              );
            } else {
              menuItems.addAll([
                PopupMenuItem(
                  value: 'print_barcode',
                  child: Row(
                    children: [
                      Icon(Icons.print, size: 20, color: Colors.blue),
                      const SizedBox(width: 8),
                      const Text('Print Barcode'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'reassign_barcode',
                  child: Row(
                    children: [
                      Icon(Icons.qr_code_2, size: 20, color: Colors.orange),
                      const SizedBox(width: 8),
                      const Text('Reassign Barcode'),
                    ],
                  ),
                ),
                // PopupMenuItem(
                //   value: 'remove_barcode',
                //   child: Row(
                //     children: [
                //       Icon(Icons.remove_circle_outline, size: 20, color: Colors.red),
                //       const SizedBox(width: 8),
                //       const Text('Remove Barcode'),
                //     ],
                //   ),
                // ),
              ]);
            }

            // menuItems.add(
            //   PopupMenuItem(
            //     value: item.isActive ? 'deactivate' : 'activate',
            //     child: Row(
            //       children: [
            //         Icon(
            //           item.isActive ? Icons.toggle_off : Icons.toggle_on,
            //           size: 20,
            //           color: item.isActive ? Colors.orange : Colors.green,
            //         ),
            //         const SizedBox(width: 8),
            //         Text(item.isActive ? 'Deactivate' : 'Activate'),
            //       ],
            //     ),
            //   ),
            // );

            return menuItems;
          },
        )
            : null,
        onTap: () {
          // Navigate to item details or edit screen for admin
          if (isAdmin) {
            _navigateToEditItem(item);
          }
        },
      ),
    );
  }

  void _handleItemAction(String value, Item item, ItemsProvider itemsProvider) {
    switch (value) {
      case 'edit':
        _navigateToEditItem(item);
        break;
      case 'generate_barcode':
        _generateBarcodeForItem(item, itemsProvider);
        break;
      case 'print_barcode':
        _printBarcode(item);
        break;
      case 'reassign_barcode':
        _reassignBarcodeForItem(item, itemsProvider);
        break;
      case 'remove_barcode':
        _removeBarcodeFromItem(item, itemsProvider);
        break;
      case 'activate':
      case 'deactivate':
        _toggleItemStatus(item, itemsProvider);
        break;
    }
  }

  void _generateBarcodeForItem(Item item, ItemsProvider itemsProvider) {
    final barcode = itemsProvider.generateBarcode();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Generate Barcode'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Generated Barcode: $barcode'),
            const SizedBox(height: 16),
            const Text(
              'This barcode will be permanently assigned to the item.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text('Assign this barcode to "${item.name}"?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await itemsProvider.assignBarcode(
                itemId: item.id,
                barcode: barcode,
                overwrite: false,
              );

              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Barcode assigned to ${item.name}'),
                    backgroundColor: Colors.green,
                  ),
                );
                // Refresh the items list
                await _loadItems();
              } else if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to assign barcode: ${itemsProvider.errorMessage}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Assign Permanently'),
          ),
        ],
      ),
    );
  }

  void _reassignBarcodeForItem(Item item, ItemsProvider itemsProvider) {
    final barcode = itemsProvider.generateBarcode();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reassign Barcode'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Current Barcode: ${item.barcode}'),
            const SizedBox(height: 8),
            Text('New Barcode: $barcode'),
            const SizedBox(height: 16),
            const Text(
              'This will replace the existing barcode permanently.',
              style: TextStyle(fontSize: 14, color: Colors.orange),
            ),
            const SizedBox(height: 8),
            Text('Replace barcode for "${item.name}"?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await itemsProvider.assignBarcode(
                itemId: item.id,
                barcode: barcode,
                overwrite: true,
              );

              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Barcode reassigned to ${item.name}'),
                    backgroundColor: Colors.green,
                  ),
                );
                // Refresh the items list
                await _loadItems();
              } else if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to reassign barcode: ${itemsProvider.errorMessage}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text(
              'Reassign',
              style: TextStyle(color: Colors.orange),
            ),
          ),
        ],
      ),
    );
  }

  void _removeBarcodeFromItem(Item item, ItemsProvider itemsProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Barcode'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Current Barcode: ${item.barcode}'),
            const SizedBox(height: 16),
            const Text(
              'This will permanently remove the barcode from the item.',
              style: TextStyle(fontSize: 14, color: Colors.red),
            ),
            const SizedBox(height: 8),
            Text('Remove barcode from "${item.name}"?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              // To remove barcode, we assign an empty string with overwrite
              final success = await itemsProvider.assignBarcode(
                itemId: item.id,
                barcode: '',
                overwrite: true,
              );

              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Barcode removed from ${item.name}'),
                    backgroundColor: Colors.green,
                  ),
                );
                // Refresh the items list
                await _loadItems();
              } else if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to remove barcode: ${itemsProvider.errorMessage}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text(
              'Remove',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _toggleItemStatus(Item item, ItemsProvider itemsProvider) {
    final newStatus = item.isActive ? 'inactive' : 'active';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${newStatus == 'active' ? 'Activate' : 'Deactivate'} Item'),
        content: Text(
          'Are you sure you want to ${newStatus == 'active' ? 'activate' : 'deactivate'} "${item.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await itemsProvider.updateItem(
                id: item.id,
                name: item.name,
                unit: item.unit ?? 'pieces',
                threshold: item.threshold ?? 0,
                status: newStatus,
              );

              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Item ${newStatus == 'active' ? 'activated' : 'deactivated'}'),
                    backgroundColor: Colors.green,
                  ),
                );
                // Refresh the items list
                await _loadItems();
              } else if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to update item: ${itemsProvider.errorMessage}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Text(newStatus == 'active' ? 'Activate' : 'Deactivate'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _barcodeController.dispose();
    super.dispose();
  }
}