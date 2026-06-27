import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../providers/transfer_provider.dart';

class TransferReviewScreen extends StatefulWidget {
  final Map<String, dynamic> transfer;

  const TransferReviewScreen({super.key, required this.transfer});

  @override
  State<TransferReviewScreen> createState() => _TransferReviewScreenState();
}

class _TransferReviewScreenState extends State<TransferReviewScreen> {
  final _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Pre-fill existing note if present
    final existingNote = widget.transfer['note']?.toString() ?? '';
    _noteController.text = existingNote;
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _handleReview(bool approved) async {
    final prov = context.read<TransferProvider>();
    final success = await prov.reviewTransfer(
      transactionId: widget.transfer['_id'],
      approved: approved,
      note: _noteController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(approved ? 'Transfer approved successfully!' : 'Transfer rejected.'),
        backgroundColor: approved ? Colors.green : Colors.orange,
      ));
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(prov.error.isNotEmpty ? prov.error : 'Failed to process transfer.'),
        backgroundColor: Colors.red,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final fromLocation = widget.transfer['fromLocationId'] is Map
        ? widget.transfer['fromLocationId']['name'] ?? 'N/A'
        : 'N/A';
    final toLocation = widget.transfer['toLocationId'] is Map
        ? widget.transfer['toLocationId']['name'] ?? 'N/A'
        : 'N/A';
    final itemData = widget.transfer['itemId'] is Map ? widget.transfer['itemId'] as Map : {};
    final itemName = itemData['name']?.toString() ?? 'N/A';
    final itemSku = itemData['sku']?.toString() ?? 'N/A';
    final itemUnit = itemData['unit']?.toString() ?? 'N/A';
    final itemThreshold = itemData['threshold']?.toString() ?? 'N/A';
    final quantity = widget.transfer['quantity']?.toString() ?? '0';
    final createdBy = widget.transfer['createdBy'] is Map
        ? widget.transfer['createdBy']['name']?.toString() ?? 'N/A'
        : 'N/A';

    DateTime? createdAt;
    try {
      if (widget.transfer['createdAt'] != null) {
        createdAt = DateTime.parse(widget.transfer['createdAt'].toString());
      }
    } catch (_) {}

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Review Transfer'),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
      ),
      body: Consumer<TransferProvider>(
        builder: (context, prov, _) {
          if (prov.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Item Information ──────────────────────────────────────
                Card(
                  elevation: 2,
                  shadowColor: Colors.black12,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionHeader('Item Information'),
                        _row(Icons.inventory_2_outlined, 'Name', itemName),
                        _row(Icons.tag, 'SKU', itemSku),
                        _row(Icons.scale_outlined, 'Unit', itemUnit),
                        _row(Icons.warning_amber_outlined, 'Threshold', itemThreshold),
                        _row(Icons.numbers_outlined, 'Quantity', quantity),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // ── Transfer Information ──────────────────────────────────
                Card(
                  elevation: 2,
                  shadowColor: Colors.black12,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionHeader('Transfer Information'),
                        _row(Icons.output_outlined, 'From', fromLocation),
                        _row(Icons.input_outlined, 'To', toLocation),
                        _row(Icons.person_outline, 'Requested By', createdBy),
                        if (createdAt != null)
                          _row(Icons.schedule, 'Requested At',
                              DateFormat('MMM dd, yyyy HH:mm').format(createdAt)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // ── Review Note ───────────────────────────────────────────
                Text('Review Note (Optional)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey[800])),
                const SizedBox(height: 8),
                TextField(
                  controller: _noteController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    hintText: 'Add comments or reason for approval / rejection...',
                    prefixIcon: const Icon(Icons.note_alt_outlined),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 30),

                // ── Action Buttons ────────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: prov.isLoading ? null : () => _handleReview(false),
                        icon: const Icon(Icons.close, color: Colors.white),
                        label: const Text('REJECT', style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: prov.isLoading ? null : () => _handleReview(true),
                        icon: const Icon(Icons.check, color: Colors.white),
                        label: const Text('APPROVE', style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _sectionHeader(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w700,
            color: Colors.grey[500], letterSpacing: 1.1,
          ),
        ),
      );

  Widget _row(IconData icon, String label, String value) {
    if (value.isEmpty || value == 'N/A' && label != 'SKU') return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          SizedBox(width: 100, child: Text(label, style: TextStyle(fontWeight: FontWeight.w500, color: Colors.grey[700], fontSize: 13))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}
