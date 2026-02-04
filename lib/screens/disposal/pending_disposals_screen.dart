import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:stock_buddy/providers/disposal_provider.dart';

class PendingDisposalsScreen extends StatefulWidget {
  const PendingDisposalsScreen({Key? key}) : super(key: key);

  @override
  State<PendingDisposalsScreen> createState() => _PendingDisposalsScreenState();
}

class _PendingDisposalsScreenState extends State<PendingDisposalsScreen> {
  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DisposalProvider>(context, listen: false).fetchPendingDisposals();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pending Disposals'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              Provider.of<DisposalProvider>(context, listen: false).fetchPendingDisposals();
            },
          ),
        ],
      ),
      body: Consumer<DisposalProvider>(
        builder: (context, disposalProvider, child) {
          if (disposalProvider.isLoading && disposalProvider.pendingDisposals.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (disposalProvider.error.isNotEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Error: ${disposalProvider.error}',
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        disposalProvider.fetchPendingDisposals();
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (disposalProvider.pendingDisposals.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.delete_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No pending disposal requests',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'All disposal requests have been reviewed',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => disposalProvider.fetchPendingDisposals(),
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 20),
              itemCount: disposalProvider.pendingDisposals.length,
              itemBuilder: (context, index) {
                final disposal = disposalProvider.pendingDisposals[index];
                return DisposalCard(disposal: disposal);
              },
            ),
          );
        },
      ),
    );
  }
}

class DisposalCard extends StatelessWidget {
  final Map<String, dynamic> disposal;

  const DisposalCard({Key? key, required this.disposal}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Parsing Item Data
    final itemId = disposal['itemId'];
    final itemName = itemId is Map ? itemId['name'] ?? 'Unknown Item' : 'Unknown Item';
    final sku = itemId is Map ? itemId['sku'] ?? 'No SKU' : 'No SKU';

    // Parsing Location Data
    final fromLocation = disposal['fromLocationId'];
    final locationName = fromLocation is Map ? fromLocation['name'] ?? 'Unknown Location' : 'Unknown Location';

    final quantity = disposal['quantity']?.toString() ?? '0';
    final reason = disposal['reason'] ?? 'Unknown Reason';

    final createdBy = disposal['createdBy'] is Map
        ? disposal['createdBy']['name'] ?? 'Unknown User'
        : 'Unknown User';

    final note = disposal['note'];
    final photo = disposal['photo'];

    // Ticket ID / Serial Number Logic
    String ticketId = disposal['_id'] ?? '';
    String displayId = ticketId.length > 6 ? ticketId.substring(ticketId.length - 6).toUpperCase() : ticketId;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      elevation: 3.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with Ticket ID and Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.grey.shade400),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Ticket #: ',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                      Text(
                        displayId,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _getReasonColor(reason).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _getReasonColor(reason)),
                  ),
                  child: Text(
                    reason,
                    style: TextStyle(
                      color: _getReasonColor(reason),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Item Info
            Text(
              itemName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'SKU: $sku',
              style: TextStyle(color: Colors.grey[700], fontSize: 13),
            ),

            const Divider(height: 24),

            // Disposal details
            _buildDetailRow(Icons.location_on_outlined, 'Location:', locationName),
            _buildDetailRow(Icons.inventory_2_outlined, 'Quantity:', quantity),
            _buildDetailRow(Icons.person_outline, 'Requested by:', createdBy),

            if (note != null && note.toString().isNotEmpty)
              _buildDetailRow(Icons.note_alt_outlined, 'Note:', note),

            const SizedBox(height: 16),

            // Photo section
            if (photo != null && photo.toString().isNotEmpty)
              _buildPhotoSection(context, photo.toString()),

            const SizedBox(height: 16),

            // Action buttons
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 8),
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[800],
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

  Widget _buildPhotoSection(BuildContext context, String base64Image) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Evidence Photo (Tap to enlarge):',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _showFullScreenImage(context, base64Image),
          child: Container(
            width: double.infinity,
            height: 180,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey.shade50,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: _buildImageFromBase64(base64Image, fit: BoxFit.cover),
            ),
          ),
        ),
      ],
    );
  }

  void _showFullScreenImage(BuildContext context, String base64Image) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(10),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            InteractiveViewer(
              panEnabled: true,
              minScale: 0.5,
              maxScale: 4,
              child: Container(
                width: double.infinity,
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.8,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.black,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _buildImageFromBase64(base64Image, fit: BoxFit.contain),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: Colors.black54,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageFromBase64(String base64Image, {BoxFit fit = BoxFit.cover}) {
    try {
      // Handle potential data URI scheme prefix
      String cleanBase64 = base64Image;
      if (base64Image.contains(',')) {
        cleanBase64 = base64Image.split(',').last;
      }

      final imageBytes = base64.decode(cleanBase64);
      return Image.memory(
        imageBytes,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.broken_image, color: Colors.grey, size: 40),
                SizedBox(height: 4),
                Text('Image load failed', style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        },
      );
    } catch (e) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 40),
            SizedBox(height: 4),
            Text('Invalid Data', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _handleApproval(context, false),
            icon: const Icon(Icons.close, size: 20, color: Colors.red),
            label: const Text(
              'REJECT',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              side: const BorderSide(color: Colors.red),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _handleApproval(context, true),
            icon: const Icon(Icons.check, size: 20, color: Colors.white),
            label: const Text(
              'APPROVE',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleApproval(BuildContext context, bool approved) async {
    final disposalProvider = Provider.of<DisposalProvider>(context, listen: false);

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          approved ? 'Approve Disposal?' : 'Reject Disposal?',
          style: TextStyle(
            color: approved ? Colors.green : Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          approved
              ? 'Are you sure you want to approve this request? This action will permanently remove the item from inventory.'
              : 'Are you sure you want to reject this request?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: approved ? Colors.green : Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(approved ? 'Confirm Approve' : 'Confirm Reject'),
          ),
        ],
      ),
    );

    if (result == true) {
      if (!context.mounted) return;

      final success = await disposalProvider.approveDisposal(
        transactionId: disposal['_id'],
        approved: approved,
      );

      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              approved
                  ? 'Request Approved Successfully'
                  : 'Request Rejected Successfully',
            ),
            backgroundColor: approved ? Colors.green : Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Color _getReasonColor(String reason) {
    switch (reason.toLowerCase()) {
      case 'broken':
      case 'damaged':
        return Colors.orange;
      case 'expired':
        return Colors.red;
      case 'obsolete':
      case 'old':
        return Colors.blue;
      case 'lost':
      case 'theft':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}