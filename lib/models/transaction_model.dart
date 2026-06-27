class ChecklistItem {
  final String? id;
  final String label;
  final bool completed;

  ChecklistItem({this.id, required this.label, required this.completed});

  factory ChecklistItem.fromJson(Map<String, dynamic> json) {
    return ChecklistItem(
      id: json['_id'] ?? json['id'],
      label: json['label'] ?? '',
      completed: json['completed'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'label': label,
        'completed': completed,
      };
}

class Transaction {
  final String id;
  final String type;
  final String status;

  // Item (populated)
  final String? itemId; // raw ObjectId (for client-side filtering)
  final String itemName;
  final String? itemSku;
  final String? itemModelNumber;
  final String? itemSerialNumber; // item-level serial (from ITEM_POPULATE_SELECT)
  final String? itemPurchaseDate; // item-level purchase date
  final String? itemUnit;

  // Locations (populated — name embedded)
  final String? fromLocation;
  final String? toLocation;
  final String? fromLocationId;
  final String? toLocationId;

  // Personnel (populated — name embedded)
  final String? createdByName;
  final String? createdByEmail;
  final String? approvedByName;
  final String? managerId; // raw ObjectId, not populated by backend

  // Dates
  final DateTime createdAt;
  final DateTime? approvedAt;
  final DateTime? updatedAt;

  // Details
  final int quantity;
  final String? note;
  final String? reason;
  final String? photo;
  final String? vendorName;
  final String? serialNumber;
  final List<ChecklistItem> repairReturnChecklist;

  Transaction({
    required this.id,
    required this.type,
    required this.status,
    this.itemId,
    required this.itemName,
    this.itemSku,
    this.itemModelNumber,
    this.itemSerialNumber,
    this.itemPurchaseDate,
    this.itemUnit,
    this.fromLocation,
    this.toLocation,
    this.fromLocationId,
    this.toLocationId,
    this.createdByName,
    this.createdByEmail,
    this.approvedByName,
    this.managerId,
    required this.quantity,
    required this.createdAt,
    this.approvedAt,
    this.updatedAt,
    this.note,
    this.reason,
    this.photo,
    this.vendorName,
    this.serialNumber,
    this.repairReturnChecklist = const [],
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    try {
      // ── Item (populated) ────────────────────────────────────────────────────
      String itemName = 'Unknown Item';
      String? parsedItemId;
      String? itemSku;
      String? itemModelNumber;
      String? itemSerialNumber;
      String? itemPurchaseDate;
      String? itemUnit;

      final rawItem = json['itemId'];
      if (rawItem is Map) {
        parsedItemId = rawItem['_id']?.toString();
        itemName = rawItem['name']?.toString() ?? 'Unknown Item';
        itemSku = rawItem['sku']?.toString();
        itemModelNumber = rawItem['modelNumber']?.toString();
        itemSerialNumber = rawItem['serialNumber']?.toString();
        itemPurchaseDate = rawItem['purchaseDate']?.toString();
        itemUnit = rawItem['unit']?.toString();
      } else if (rawItem is String) {
        parsedItemId = rawItem;
        itemName = 'Item ${rawItem.length > 5 ? rawItem.substring(0, 5) : rawItem}...';
      }

      // ── Locations (populated) ────────────────────────────────────────────────
      String? fromLocName;
      String? fromLocId;
      final rawFrom = json['fromLocationId'];
      if (rawFrom is Map) {
        fromLocName = rawFrom['name']?.toString();
        fromLocId = rawFrom['_id']?.toString();
      } else if (rawFrom is String) {
        fromLocId = rawFrom;
      }

      String? toLocName;
      String? toLocId;
      final rawTo = json['toLocationId'];
      if (rawTo is Map) {
        toLocName = rawTo['name']?.toString();
        toLocId = rawTo['_id']?.toString();
      } else if (rawTo is String) {
        toLocId = rawTo;
      }

      // ── Personnel (populated) ────────────────────────────────────────────────
      String? createdByName;
      String? createdByEmail;
      final rawCreatedBy = json['createdBy'];
      if (rawCreatedBy is Map) {
        createdByName = rawCreatedBy['name']?.toString();
        createdByEmail = rawCreatedBy['email']?.toString();
      }

      String? approvedByName;
      final rawApprovedBy = json['approvedBy'];
      if (rawApprovedBy is Map) {
        approvedByName = rawApprovedBy['name']?.toString();
      }

      // managerId is not populated — just a raw ObjectId string or null
      final rawManagerId = json['managerId'];
      final String? managerId =
          rawManagerId is String ? rawManagerId : rawManagerId is Map ? rawManagerId['_id']?.toString() : null;

      // ── Dates ────────────────────────────────────────────────────────────────
      DateTime createdAt = DateTime.now();
      try {
        if (json['createdAt'] != null) createdAt = DateTime.parse(json['createdAt']);
      } catch (_) {}

      DateTime? approvedAt;
      try {
        if (json['approvedAt'] != null) approvedAt = DateTime.parse(json['approvedAt']);
      } catch (_) {}

      DateTime? updatedAt;
      try {
        if (json['updatedAt'] != null) updatedAt = DateTime.parse(json['updatedAt']);
      } catch (_) {}

      // ── Checklist ────────────────────────────────────────────────────────────
      List<ChecklistItem> checklist = [];
      final rawChecklist = json['repairReturnChecklist'] ?? json['checklist'];
      if (rawChecklist is List) {
        checklist = rawChecklist.map((e) => ChecklistItem.fromJson(e)).toList();
      }

      return Transaction(
        id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
        type: json['type']?.toString() ?? 'UNKNOWN',
        status: json['status']?.toString() ?? 'approved',
        itemId: parsedItemId,
        itemName: itemName,
        itemSku: itemSku,
        itemModelNumber: itemModelNumber,
        itemSerialNumber: itemSerialNumber,
        itemPurchaseDate: itemPurchaseDate,
        itemUnit: itemUnit,
        fromLocation: fromLocName,
        toLocation: toLocName,
        fromLocationId: fromLocId,
        toLocationId: toLocId,
        createdByName: createdByName,
        createdByEmail: createdByEmail,
        approvedByName: approvedByName,
        managerId: managerId,
        quantity: (json['quantity'] ?? 0).toInt(),
        createdAt: createdAt,
        approvedAt: approvedAt,
        updatedAt: updatedAt,
        note: json['note']?.toString(),
        reason: json['reason']?.toString(),
        photo: json['photo']?.toString(),
        vendorName: json['vendorName']?.toString(),
        serialNumber: json['serialNumber']?.toString(),
        repairReturnChecklist: checklist,
      );
    } catch (e) {
      return Transaction(
        id: 'error-${DateTime.now().millisecondsSinceEpoch}',
        type: 'ERROR',
        status: 'error',
        itemName: 'Error loading transaction',
        quantity: 0,
        createdAt: DateTime.now(),
      );
    }
  }

  String get displayType {
    switch (type.toUpperCase()) {
      case 'ADD': return 'Add Stock';
      case 'TRANSFER': return 'Transfer';
      case 'REPAIR_OUT': return 'Send to Repair';
      case 'REPAIR_IN': return 'Return from Repair';
      case 'DISPOSE': return 'Dispose';
      default: return type;
    }
  }

  String get locationDisplay {
    switch (type.toUpperCase()) {
      case 'ADD':
        return toLocation ?? fromLocation ?? '—';
      case 'TRANSFER':
        final from = fromLocation ?? '?';
        final to = toLocation ?? '?';
        return '$from → $to';
      case 'REPAIR_OUT':
        return '${fromLocation ?? '?'} → Repair';
      case 'REPAIR_IN':
        return 'Repair → ${toLocation ?? '?'}';
      case 'DISPOSE':
        return '${fromLocation ?? '?'} → Disposed';
      default:
        return fromLocation ?? toLocation ?? '—';
    }
  }

  String get displayItem => itemSku != null ? '$itemName ($itemSku)' : itemName;

  // Backward-compat alias used by home_screen
  String get fromToDisplay => locationDisplay;
}
