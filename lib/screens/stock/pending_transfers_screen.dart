import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/transfer_provider.dart';
import 'transfer_review_screen.dart';

class PendingTransfersScreen extends StatefulWidget {
  const PendingTransfersScreen({Key? key}) : super(key: key);

  @override
  State<PendingTransfersScreen> createState() => _PendingTransfersScreenState();
}

class _PendingTransfersScreenState extends State<PendingTransfersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TransferProvider>(context, listen: false).fetchPendingTransfers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pending Transfers'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              Provider.of<TransferProvider>(context, listen: false).fetchPendingTransfers();
            },
          ),
        ],
      ),
      body: Consumer<TransferProvider>(
        builder: (context, transferProvider, child) {
          if (transferProvider.isLoading && transferProvider.pendingTransfers.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (transferProvider.error.isNotEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Error: ${transferProvider.error}',
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      transferProvider.fetchPendingTransfers();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (transferProvider.pendingTransfers.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No pending transfers',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'All transfer requests have been reviewed',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => transferProvider.fetchPendingTransfers(),
            child: ListView.builder(
              itemCount: transferProvider.pendingTransfers.length,
              itemBuilder: (context, index) {
                final transfer = transferProvider.pendingTransfers[index];
                return TransferCard(transfer: transfer);
              },
            ),
          );
        },
      ),
    );
  }
}

class TransferCard extends StatelessWidget {
  final Map<String, dynamic> transfer;

  const TransferCard({Key? key, required this.transfer}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final fromLocation = transfer['fromLocationId'] is Map
        ? transfer['fromLocationId']['name'] ?? 'N/A'
        : 'N/A';

    final toLocation = transfer['toLocationId'] is Map
        ? transfer['toLocationId']['name'] ?? 'N/A'
        : 'N/A';

    final itemName = transfer['itemId'] is Map
        ? transfer['itemId']['name'] ?? 'N/A'
        : 'N/A';

    final quantity = transfer['quantity']?.toString() ?? '0';
    final createdBy = transfer['createdBy'] is Map
        ? transfer['createdBy']['name'] ?? 'N/A'
        : 'N/A';

    return Card(
      margin: const EdgeInsets.all(8.0),
      elevation: 2.0,
      child: ListTile(
        title: Text(
          'Transfer #${transfer['_id']?.toString().substring(0, 8) ?? 'N/A'}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Item: $itemName'),
            Text('From: $fromLocation'),
            Text('To: $toLocation'),
            Text('Quantity: $quantity'),
            Text('Created by: $createdBy'),
            Text('Created: ${_formatDate(transfer['createdAt'])}'),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TransferReviewScreen(transfer: transfer),
            ),
          );
        },
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }
}