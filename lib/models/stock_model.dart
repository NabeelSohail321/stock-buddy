class StockAddRequest {
  final String itemId;
  final String locationId;
  final int quantity;
  final String? note;
  final String? photo;

  StockAddRequest({
    required this.itemId,
    required this.locationId,
    required this.quantity,
    this.note,
    this.photo,
  });

  Map<String, dynamic> toJson() {
    return {
      'itemId': itemId,
      'locationId': locationId,
      'quantity': quantity,
      'note': note,
      'photo': photo,
    };
  }
}

class StockResponse {
  final String id;
  final String itemId;
  final String locationId;
  final int quantity;
  final String? note;
  final String? photo;
  final DateTime timestamp;

  StockResponse({
    required this.id,
    required this.itemId,
    required this.locationId,
    required this.quantity,
    this.note,
    this.photo,
    required this.timestamp,
  });

  factory StockResponse.fromJson(Map<String, dynamic> json) {
    return StockResponse(
      id: json['_id']?.toString() ?? '',
      itemId: json['itemId']?.toString() ?? '',
      locationId: json['locationId']?.toString() ?? '',
      quantity: json['quantity'] is int ? json['quantity'] : int.tryParse(json['quantity']?.toString() ?? '0') ?? 0,
      note: json['note']?.toString(),
      photo: json['photo']?.toString(),
      timestamp: json['timestamp'] != null ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now() : DateTime.now(),
    );
  }
}