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
  final String? image; // New field for image URL or base64
  final List<ItemLocation> locations;
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
    this.image, // New optional parameter
    required this.locations,
    this.createdAt,
    this.updatedAt,
  });

  factory Item.fromJson(Map<String, dynamic> json) {
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
      image: json['image']?.toString(), // Parse the new image field
      locations: json['locations'] is List
          ? (json['locations'] as List).map((loc) => ItemLocation.fromJson(loc)).toList()
          : [],
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