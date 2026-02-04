import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/transfer_provider.dart';

class TransferReviewScreen extends StatefulWidget {
  final Map<String, dynamic> transfer;

  const TransferReviewScreen({Key? key, required this.transfer}) : super(key: key);

  @override
  State<TransferReviewScreen> createState() => _TransferReviewScreenState();
}

class _TransferReviewScreenState extends State<TransferReviewScreen> {
  final TextEditingController _noteController = TextEditingController();
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final transferProvider = Provider.of<TransferProvider>(context);

    // Extract data from nested objects
    final fromLocation = widget.transfer['fromLocationId'] is Map
        ? widget.transfer['fromLocationId']['name'] ?? 'N/A'
        : 'N/A';

    final toLocation = widget.transfer['toLocationId'] is Map
        ? widget.transfer['toLocationId']['name'] ?? 'N/A'
        : 'N/A';

    final itemData = widget.transfer['itemId'] is Map
        ? widget.transfer['itemId']
        : {};

    final itemName = itemData['name'] ?? 'N/A';
    final itemSku = itemData['sku'] ?? 'N/A';
    final itemUnit = itemData['unit'] ?? 'N/A';
    final itemThreshold = itemData['threshold']?.toString() ?? 'N/A';

    final quantity = widget.transfer['quantity']?.toString() ?? '0';
    final createdBy = widget.transfer['createdBy'] is Map
        ? widget.transfer['createdBy']['name'] ?? 'N/A'
        : 'N/A';

    final createdAt = _formatDate(widget.transfer['createdAt']);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Transfer'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _isProcessing || transferProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Transfer Details Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Transfer #${widget.transfer['_id']?.toString().substring(0, 8) ?? 'N/A'}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
          
                      // Item Information
                      _buildDetailSection('ITEM INFORMATION', [
                        _buildDetailRow('Name:', itemName),
                        _buildDetailRow('SKU:', itemSku),
                        _buildDetailRow('Unit:', itemUnit),
                        _buildDetailRow('Threshold:', itemThreshold),
                        _buildDetailRow('Transfer Quantity:', quantity),
                      ]),
          
                      const SizedBox(height: 16),
          
                      // Transfer Information
                      _buildDetailSection('TRANSFER INFORMATION', [
                        _buildDetailRow('From:', fromLocation),
                        _buildDetailRow('To:', toLocation),
                        _buildDetailRow('Status:', widget.transfer['status'] ?? 'pending'),
                        _buildDetailRow('Created by:', createdBy),
                        _buildDetailRow('Created at:', createdAt),
                      ]),
                    ],
                  ),
                ),
              ),
          
              const SizedBox(height: 20),
          
              // Note Field
              _buildNoteField(),
          
              const SizedBox(height: 30),
          
              // Action Buttons
              _buildActionButtons(context, transferProvider),
          
              if (transferProvider.error.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Text(
                    'Error: ${transferProvider.error}',
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w400),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Review Note (Optional)',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _noteController,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Enter any comments or reasons for approval/rejection...',
            contentPadding: EdgeInsets.all(12),
          ),
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, TransferProvider transferProvider) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _handleReview(context, transferProvider, false),
            icon: const Icon(Icons.close, color: Colors.white),
            label: const Text('REJECT', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _handleReview(context, transferProvider, true),
            icon: const Icon(Icons.check, color: Colors.white),
            label: const Text('APPROVE', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleReview(
      BuildContext context,
      TransferProvider transferProvider,
      bool approved,
      ) async {
    setState(() {
      _isProcessing = true;
    });

    try {
      await transferProvider.reviewTransfer(
        transactionId: widget.transfer['_id'],
        approved: approved,
        note: _noteController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              approved ? 'Transfer approved successfully!' : 'Transfer rejected successfully!',
            ),
            backgroundColor: approved ? Colors.green : Colors.orange,
          ),
        );

        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
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

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }
}