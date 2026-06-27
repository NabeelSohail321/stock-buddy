class ItemLocation {
  final String locationId;
  final String name;
  final int quantity;

  ItemLocation({
    required this.locationId,
    required this.name,
    required this.quantity,
  });

  factory ItemLocation.fromJson(Map<String, dynamic> json) {
    return ItemLocation(
      locationId: json['locationId'] is String
          ? json['locationId']
          : (json['locationId']?['_id']?.toString() ?? ''),
      name: json['locationId'] is String
          ? 'Unknown Location'
          : (json['locationId']?['name']?.toString() ?? 'Unknown Location'),
      quantity: json['quantity'] is int ? json['quantity'] : int.tryParse(json['quantity']?.toString() ?? '0') ?? 0,
    );
  }
}

class Item {
  final String id;
  final String name;
  final String? sku;
  final String? barcode;
  final String? unit;
  final int? threshold;
  final int? totalStock;
  final String? stockStatus;
  final String? status;
  final String? image;
  final String? modelNumber;
  final String? serialNumber;
  final DateTime? purchaseDate;
  final List<ItemLocation> locations;
  final String? assignedManagerId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Item({
    required this.id,
    required this.name,
    this.sku,
    this.barcode,
    this.unit,
    this.threshold,
    this.totalStock,
    this.stockStatus,
    this.status,
    this.image,
    this.modelNumber,
    this.serialNumber,
    this.purchaseDate,
    required this.locations,
    this.assignedManagerId,
    this.createdAt,
    this.updatedAt,
  });

  factory Item.fromJson(Map<String, dynamic> json) {
    // assignedManagerId is the backend field name (stored as ObjectId, returned
    // as plain string or populated object { _id, name, email }).
    final rawManager = json['assignedManagerId'];
    final String? parsedManagerId = rawManager is String
        ? rawManager
        : rawManager is Map
            ? rawManager['_id']?.toString()
            : null;

    return Item(
      id: json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unknown Item',
      sku: json['sku']?.toString(),
      barcode: json['barcode']?.toString(),
      unit: json['unit']?.toString(),
      threshold: json['threshold'] is int ? json['threshold'] : int.tryParse(json['threshold']?.toString() ?? '0'),
      totalStock: json['totalStock'] is int ? json['totalStock'] : int.tryParse(json['totalStock']?.toString() ?? '0'),
      stockStatus: json['stockStatus']?.toString(),
      status: json['status']?.toString(),
      image: json['image']?.toString(),
      modelNumber: (json['modelNumber'] ?? json['model_number'])?.toString(),
      serialNumber: (json['serialNumber'] ?? json['serial_number'])?.toString(),
      purchaseDate: (json['purchaseDate'] ?? json['purchase_date']) != null
          ? DateTime.tryParse((json['purchaseDate'] ?? json['purchase_date']).toString())
          : null,
      locations: json['locations'] is List
          ? (json['locations'] as List).map((loc) => ItemLocation.fromJson(loc)).toList()
          : [],
      assignedManagerId: parsedManagerId,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'].toString()) : null,
    );
  }

  bool matchesSearch(String query) {
    final lowerQuery = query.toLowerCase();
    return name.toLowerCase().contains(lowerQuery) ||
        (sku?.toLowerCase().contains(lowerQuery) ?? false) ||
        (unit?.toLowerCase().contains(lowerQuery) ?? false) ||
        (barcode?.toLowerCase().contains(lowerQuery) ?? false);
  }

  // Helper method to get the effective status
  String get effectiveStatus {
    return status ?? stockStatus ?? 'active';
  }

  // Helper method to check if item is active
  bool get isActive {
    final currentStatus = effectiveStatus.toLowerCase();
    return currentStatus == 'active' ||
        currentStatus == 'sufficient' ||
        currentStatus == 'in_stock';
  }

  // Helper method to check if item has an image
  bool get hasImage => image != null && image!.isNotEmpty;
}