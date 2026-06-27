import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../providers/transfer_provider.dart';
import 'transfer_review_screen.dart';

class PendingTransfersScreen extends StatefulWidget {
  const PendingTransfersScreen({super.key});

  @override
  State<PendingTransfersScreen> createState() => _PendingTransfersScreenState();
}

class _PendingTransfersScreenState extends State<PendingTransfersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TransferProvider>().fetchPendingTransfers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Pending Transfers'),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<TransferProvider>().fetchPendingTransfers(),
          ),
        ],
      ),
      body: Consumer<TransferProvider>(
        builder: (context, prov, _) {
          if (prov.isLoading && prov.pendingTransfers.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (prov.error.isNotEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, size: 56, color: Colors.red.shade300),
                  const SizedBox(height: 12),
                  Text(prov.error, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => prov.fetchPendingTransfers(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (prov.pendingTransfers.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.compare_arrows, size: 72, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No pending transfers', style: TextStyle(fontSize: 18, color: Colors.grey)),
                  SizedBox(height: 8),
                  Text('All transfer requests have been reviewed',
                      style: TextStyle(fontSize: 14, color: Colors.grey), textAlign: TextAlign.center),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => prov.fetchPendingTransfers(),
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: prov.pendingTransfers.length,
              itemBuilder: (context, index) =>
                  _TransferCard(transfer: prov.pendingTransfers[index]),
            ),
          );
        },
      ),
    );
  }
}

class _TransferCard extends StatelessWidget {
  final Map<String, dynamic> transfer;

  const _TransferCard({required this.transfer});

  @override
  Widget build(BuildContext context) {
    final fromLocation = transfer['fromLocationId'] is Map
        ? transfer['fromLocationId']['name'] ?? 'N/A'
        : 'N/A';
    final toLocation = transfer['toLocationId'] is Map
        ? transfer['toLocationId']['name'] ?? 'N/A'
        : 'N/A';
    final itemData = transfer['itemId'] is Map ? transfer['itemId'] as Map : {};
    final itemName = itemData['name']?.toString() ?? 'Unknown Item';
    final itemSku = itemData['sku']?.toString();
    final quantity = transfer['quantity']?.toString() ?? '0';
    final createdBy = transfer['createdBy'] is Map
        ? transfer['createdBy']['name']?.toString() ?? 'N/A'
        : 'N/A';
    final note = transfer['note']?.toString();

    DateTime? createdAt;
    try {
      if (transfer['createdAt'] != null) createdAt = DateTime.parse(transfer['createdAt'].toString());
    } catch (_) {}

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => TransferReviewScreen(transfer: transfer)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              // Color accent bar
              Container(
                width: 4,
                height: 64,
                decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(4)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header row
                    Row(
                      children: [
                        _chip('PENDING', Colors.orange),
                        const Spacer(),
                        if (createdAt != null)
                          Text(DateFormat('MMM d, HH:mm').format(createdAt),
                              style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Item name
                    Text(
                      itemSku != null ? '$itemName ($itemSku)' : itemName,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    // Route + qty
                    Text(
                      'Qty: $quantity  ·  $fromLocation → $toLocation',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(children: [
                      Icon(Icons.person_outline, size: 13, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(createdBy,
                            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                    ]),
                    if (note?.isNotEmpty == true) ...[
                      const SizedBox(height: 2),
                      Row(children: [
                        Icon(Icons.note_alt_outlined, size: 13, color: Colors.grey[400]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(note!, style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                      ]),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: Colors.orange, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}
