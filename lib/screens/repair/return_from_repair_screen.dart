import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:stock_buddy/providers/items_provider.dart';
import 'package:stock_buddy/providers/repair_provider.dart';
import 'package:stock_buddy/models/location_model.dart'; // Ensure you import your Location model

class ReturnFromRepairScreen extends StatefulWidget {
  const ReturnFromRepairScreen({Key? key}) : super(key: key);

  @override
  State<ReturnFromRepairScreen> createState() => _ReturnFromRepairScreenState();
}

class _ReturnFromRepairScreenState extends State<ReturnFromRepairScreen> {
  final _formKey = GlobalKey<FormState>();
  final _returnNoteController = TextEditingController();

  String? _selectedRepairTicketId;
  String? _selectedReturnLocationId;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final repairProvider = Provider.of<RepairProvider>(context, listen: false);
      final itemsProvider = Provider.of<ItemsProvider>(context, listen: false);

      repairProvider.fetchRepairTickets();

      // Ensure we have locations loaded to resolve "Sent From" IDs
      if (itemsProvider.locations.isEmpty) {
        itemsProvider.fetchLocations();
      }
    });
  }

  Future<void> _submitReturnRequest() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedRepairTicketId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a repair ticket')),
      );
      return;
    }

    if (_selectedReturnLocationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a return location')),
      );
      return;
    }

    final repairProvider = Provider.of<RepairProvider>(context, listen: false);

    // Call the provider method to process return
    final success = await repairProvider.returnFromRepair(
      repairTicketId: _selectedRepairTicketId!,
      locationId: _selectedReturnLocationId!,
      note: _returnNoteController.text.isNotEmpty ? _returnNoteController.text : null,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Item returned from repair successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _returnNoteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Return from Repair'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Consumer<ItemsProvider>(
        builder: (context, itemsProvider, child) {
          return Consumer<RepairProvider>(
            builder: (context, repairProvider, child) {
              if (repairProvider.isLoading && repairProvider.sentRepairTickets.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. Repair Ticket Selection
                        _buildRepairTicketDropdown(repairProvider),
                        const SizedBox(height: 20),

                        // 2. Selected Ticket Details (Read-only view)
                        if (_selectedRepairTicketId != null)
                          _buildTicketDetails(repairProvider, itemsProvider),
                        const SizedBox(height: 24),

                        const Divider(thickness: 1.5),
                        const SizedBox(height: 16),
                        const Text(
                          'RETURN DETAILS',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                        const SizedBox(height: 16),

                        // 3. Location Selection (Where it's going back to)
                        _buildLocationDropdown(itemsProvider),
                        const SizedBox(height: 20),

                        // 4. Return Note (Optional)
                        _buildNoteField(),
                        const SizedBox(height: 30),

                        // Error Message Display
                        if (repairProvider.error.isNotEmpty)
                          _buildErrorWidget(repairProvider),

                        // 5. Submit Button
                        _buildSubmitButton(repairProvider),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // --- WIDGET BUILDERS ---

  Widget _buildRepairTicketDropdown(RepairProvider repairProvider) {
    final sentTickets = repairProvider.sentRepairTickets;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Repair Ticket *',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedRepairTicketId,
          isExpanded: true,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
            hintText: sentTickets.isEmpty ? 'No pending repairs' : 'Choose a repair ticket',
          ),
          items: sentTickets.map((ticket) {
            // Data Extraction
            final itemId = ticket['itemId'];
            final itemName = itemId is Map ? itemId['name'] ?? 'Unknown Item' : 'Unknown Item';

            // Logic for Serial Number / Ticket ID
            String displaySerial = _getDisplaySerial(ticket);

            return DropdownMenuItem<String>(
              value: ticket['_id'],
              child: Text(
                '$displaySerial - $itemName',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14),
              ),
            );
          }).toList(),
          onChanged: sentTickets.isEmpty ? null : (value) {
            setState(() {
              _selectedRepairTicketId = value;
              // Reset location selection usually, but user might want to keep it
            });
          },
          validator: (value) {
            if (value == null && sentTickets.isNotEmpty) {
              return 'Please select a repair ticket';
            }
            return null;
          },
        ),
        if (sentTickets.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'No items currently marked as "sent" to repair.',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildTicketDetails(RepairProvider repairProvider, ItemsProvider itemsProvider) {
    final ticket = repairProvider.sentRepairTickets.firstWhere(
          (t) => t['_id'] == _selectedRepairTicketId,
      orElse: () => {},
    );

    if (ticket.isEmpty) return const SizedBox();

    // extract data based on Mongoose Schema
    final itemId = ticket['itemId'];
    final itemName = itemId is Map ? itemId['name'] ?? 'Unknown' : 'Unknown';
    final itemSku = itemId is Map ? itemId['sku'] ?? 'N/A' : 'N/A';

    final quantity = ticket['quantity']?.toString() ?? '0';
    final vendorName = ticket['vendorName'] ?? 'N/A';
    final sentDate = _formatDate(ticket['sentDate']);
    final noteSent = ticket['note'] ?? ''; // Note when it was sent

    // Resolve "Sent From" Location Name
    String sentFromLocationName = _resolveLocationName(ticket['locationId'], itemsProvider.locations);

    // Resolve Serial Number
    String serialDisplay = _getDisplaySerial(ticket);

    return Card(
      elevation: 2,
      color: Colors.grey.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'TICKET INFORMATION',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                    fontSize: 13,
                    letterSpacing: 1.0,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.orange.shade300),
                  ),
                  child: Text(
                    (ticket['status'] ?? 'sent').toString().toUpperCase(),
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.orange.shade900),
                  ),
                ),
              ],
            ),
            const Divider(height: 20),

            // Details Rows
            _buildDetailRow('Serial #:', serialDisplay, isBold: true),
            _buildDetailRow('Item:', '$itemName ($itemSku)'),
            _buildDetailRow('Quantity:', quantity),
            _buildDetailRow('Sent From:', sentFromLocationName),
            _buildDetailRow('Vendor:', vendorName),
            _buildDetailRow('Sent Date:', sentDate),

            if (noteSent.isNotEmpty)
              _buildDetailRow('Initial Issue:', noteSent),

            // Photo
            _buildTicketImage(ticket),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketImage(Map<String, dynamic> ticket) {
    final photo = ticket['photo'];

    if (photo == null || photo.toString().isEmpty) {
      return const SizedBox();
    }

    try {
      String base64String = photo.toString();
      if (base64String.contains(',')) {
        base64String = base64String.split(',').last;
      }

      final imageBytes = base64.decode(base64String);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          const Text(
            'Evidence Photo (Tap to enlarge):',
            style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: () => _showFullScreenImage(context, imageBytes), // Handle tap here
            child: Container(
              width: double.infinity,
              height: 180,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
                color: Colors.white,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.memory(
                  imageBytes,
                  fit: BoxFit.contain, // Contain to see whole image
                  errorBuilder: (context, error, stackTrace) =>
                  const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
                ),
              ),
            ),
          ),
        ],
      );
    } catch (e) {
      return const SizedBox();
    }
  }

  void _showFullScreenImage(BuildContext context, dynamic imageBytes) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(10), // Little padding around dialog
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            InteractiveViewer(
              panEnabled: true,
              minScale: 0.5,
              maxScale: 4.0,
              child: Container(
                width: double.infinity,
                // height: MediaQuery.of(context).size.height * 0.7, // Adjust height as needed
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.black, // Dark background for better viewing
                ),
                child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(
                      imageBytes,
                      fit: BoxFit.contain,
                    )
                ),
              ),
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

  Widget _buildLocationDropdown(ItemsProvider itemsProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Return To Location *',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedReturnLocationId,
          isExpanded: true,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Select where item is being stored now',
          ),
          items: itemsProvider.locations.map((location) {
            return DropdownMenuItem<String>(
              value: location.id,
              child: Text(
                location.name,
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedReturnLocationId = value;
            });
          },
          validator: (value) => value == null ? 'Required' : null,
        ),
      ],
    );
  }

  Widget _buildNoteField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Return Notes / Repair Outcome',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _returnNoteController,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'e.g., Fixed completely, part replaced, etc.',
          ),
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100, // Fixed width for alignment
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                color: Colors.black87,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(RepairProvider repairProvider) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              repairProvider.error,
              style: const TextStyle(color: Colors.red),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.red, size: 20),
            onPressed: () => repairProvider.clearError(),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(RepairProvider repairProvider) {
    bool isDisabled = repairProvider.sentRepairTickets.isEmpty || repairProvider.isLoading;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: isDisabled ? null : _submitReturnRequest,
        icon: repairProvider.isLoading
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Icon(Icons.check_circle_outline),
        label: Text(
          repairProvider.isLoading ? 'Processing...' : 'Complete Return',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 2,
        ),
      ),
    );
  }

  // --- HELPERS ---

  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (e) {
      return dateString;
    }
  }

  // Extracts displayable serial number from ticket
  String _getDisplaySerial(Map<String, dynamic> ticket) {
    String? serial = ticket['serialNumber'];
    String id = ticket['_id'] ?? '';

    if (serial != null && serial.isNotEmpty) {
      return 'SN: $serial';
    } else {
      // Fallback to Ticket ID if no custom serial provided
      String shortId = id.length > 6 ? id.substring(id.length - 6).toUpperCase() : id;
      return 'TICKET #$shortId';
    }
  }

  // Resolves Location Name from ID object or ID string
  String _resolveLocationName(dynamic locationData, List<Location> allLocations) {
    if (locationData == null) return 'Unknown Location';

    // Case 1: Backend populated the location object
    if (locationData is Map) {
      return locationData['name'] ?? 'Unknown Location';
    }

    // Case 2: Backend sent only ID string
    if (locationData is String) {
      try {
        final loc = allLocations.firstWhere(
              (l) => l.id == locationData,
          orElse: () => Location(id: '', name: 'ID: ${locationData.substring(0,4)}...', isActive: true), // Dummy fallback
        );
        return loc.name;
      } catch (e) {
        return 'Unknown Location';
      }
    }

    return 'Unknown Location';
  }
}