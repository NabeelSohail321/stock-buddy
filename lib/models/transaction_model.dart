class Transaction {
  final String id;
  final String type;
  final String status;
  final String itemName;
  final String? itemSku;
  final int quantity;
  final DateTime createdAt;

  // Existing fields (Used for Display Names)
  final String? fromLocation;
  final String? toLocation;

  // IDs (For Provider Lookups)
  final String? fromLocationId;
  final String? toLocationId;

  // Personnel IDs
  final String? createdBy;
  final String? approvedBy;
  final DateTime? approvedAt;

  // Details
  final String? note;
  final String? reason;
  final String? photo;

  Transaction({
    required this.id,
    required this.type,
    required this.status,
    required this.itemName,
    this.itemSku,
    this.fromLocation,
    this.toLocation,
    this.fromLocationId,
    this.toLocationId,
    required this.quantity,
    required this.createdAt,
    this.createdBy,
    this.approvedBy,
    this.approvedAt,
    this.note,
    this.reason,
    this.photo,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    try {
      // 1. Parse Item
      String itemName = 'Unknown Item';
      String? itemSku;

      if (json['itemId'] != null) {
        if (json['itemId'] is Map) {
          itemName = json['itemId']['name'] ?? 'Unknown Item';
          itemSku = json['itemId']['sku'];
        } else if (json['itemId'] is String) {
          // If it's just an ID strings
          itemName = 'Item ${json['itemId'].toString().substring(0, 5)}...';
        }
      } else if (json['item'] != null) {
        if (json['item'] is Map) {
          itemName = json['item']['name'] ?? 'Unknown Item';
          itemSku = json['item']['sku'];
        } else if (json['item'] is String) {
          itemName = json['item'];
        }
      }

      // 2. Parse Locations (Extract both ID and Name)
      String? fromLocName;
      String? fromLocId;

      if (json['fromLocationId'] != null) {
        if (json['fromLocationId'] is Map) {
          fromLocName = json['fromLocationId']['name'];
          fromLocId = json['fromLocationId']['_id']; // MongoDB typically uses _id inside objects
        } else if (json['fromLocationId'] is String) {
          fromLocId = json['fromLocationId'];
          // Name remains null here, UI can fetch it via Provider using ID later
        }
      }

      String? toLocName;
      String? toLocId;

      if (json['toLocationId'] != null) {
        if (json['toLocationId'] is Map) {
          toLocName = json['toLocationId']['name'];
          toLocId = json['toLocationId']['_id'];
        } else if (json['toLocationId'] is String) {
          toLocId = json['toLocationId'];
        }
      }

      // 3. Parse Users (CreatedBy / ApprovedBy)
      String? createdById;
      if (json['createdBy'] != null) {
        if (json['createdBy'] is Map) {
          createdById = json['createdBy']['_id'];
        } else if (json['createdBy'] is String) {
          createdById = json['createdBy'];
        }
      }

      String? approvedById;
      if (json['approvedBy'] != null) {
        if (json['approvedBy'] is Map) {
          approvedById = json['approvedBy']['_id'];
        } else if (json['approvedBy'] is String) {
          approvedById = json['approvedBy'];
        }
      }

      // 4. Parse Dates
      DateTime createdAt;
      try {
        if (json['createdAt'] != null) {
          createdAt = DateTime.parse(json['createdAt']);
        } else if (json['created_at'] != null) {
          createdAt = DateTime.parse(json['created_at']);
        } else {
          createdAt = DateTime.now();
        }
      } catch (e) {
        createdAt = DateTime.now();
      }

      DateTime? approvedAt;
      if (json['approvedAt'] != null) {
        try {
          approvedAt = DateTime.parse(json['approvedAt']);
        } catch (_) {}
      }

      return Transaction(
        id: json['_id'] ?? json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
        type: json['type'] ?? 'UNKNOWN',
        status: json['status'] ?? 'pending',
        itemName: itemName,
        itemSku: itemSku,
        quantity: (json['quantity'] ?? 0).toInt(),
        createdAt: createdAt,
        // Location mapping
        fromLocation: fromLocName, // For legacy display
        fromLocationId: fromLocId, // For new ID lookup
        toLocation: toLocName,     // For legacy display
        toLocationId: toLocId,     // For new ID lookup
        // User mapping
        createdBy: createdById,
        approvedBy: approvedById,
        approvedAt: approvedAt,
        // Details
        note: json['note'],
        reason: json['reason'],
        photo: json['photo'],
      );
    } catch (e) {
      print('Error creating Transaction from JSON: $e');
      return Transaction(
        id: 'error-${DateTime.now().millisecondsSinceEpoch}',
        type: 'ERROR',
        status: 'error',
        itemName: 'Error loading item',
        quantity: 0,
        createdAt: DateTime.now(),
      );
    }
  }

  // --- Existing Getters (Preserved for Backward Compatibility) ---

  String get displayType {
    switch (type.toUpperCase()) {
      case 'ADD':
        return 'Add Stock';
      case 'TRANSFER':
        return 'Transfer';
      case 'REPAIR_OUT':
        return 'Send to Repair';
      case 'REPAIR_IN':
        return 'Return from Repair';
      case 'DISPOSE':
        return 'Dispose';
      case 'ERROR':
        return 'Error';
      default:
        return type;
    }
  }

  String get fromToDisplay {
    // Falls back to "Unknown" if names weren't embedded in JSON,
    // protecting old UI from crashing on nulls.
    switch (type.toUpperCase()) {
      case 'ADD':
        return toLocation != null ? '→ $toLocation' : 'Stock Added';
      case 'TRANSFER':
        if (fromLocation != null && toLocation != null) {
          return '$fromLocation → $toLocation';
        } else if (fromLocation != null) {
          return '$fromLocation → Unknown';
        } else if (toLocation != null) {
          return 'Unknown → $toLocation';
        } else {
          return 'Transfer';
        }
      case 'REPAIR_OUT':
        return '${fromLocation ?? 'Unknown'} → Repair Center';
      case 'REPAIR_IN':
        return 'Repair Center → ${toLocation ?? 'Unknown'}';
      case 'DISPOSE':
        return '${fromLocation ?? 'Unknown'} → Dispose';
      default:
        return '${fromLocation ?? 'Unknown'} → ${toLocation ?? 'Unknown'}';
    }
  }

  String get displayItem {
    if (itemSku != null) {
      return '$itemName ($itemSku)';
    }
    return itemName;
  }
}