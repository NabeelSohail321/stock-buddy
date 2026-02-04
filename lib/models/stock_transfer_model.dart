class StockTransferRequest {
  final String itemId;
  final String fromLocationId;
  final String toLocationId;
  final int quantity;
  final String? note;

  StockTransferRequest({
    required this.itemId,
    required this.fromLocationId,
    required this.toLocationId,
    required this.quantity,
    this.note,
  });

  Map<String, dynamic> toJson() {
    return {
      'itemId': itemId,
      'fromLocationId': fromLocationId,
      'toLocationId': toLocationId,
      'quantity': quantity,
      if (note != null && note!.isNotEmpty) 'note': note,
    };
  }
}

class StockTransferResponse {
  final String message;
  final TransferTransaction transaction;

  StockTransferResponse({
    required this.message,
    required this.transaction,
  });

  factory StockTransferResponse.fromJson(Map<String, dynamic> json) {
    return StockTransferResponse(
      message: json['message'] ?? 'Transfer initiated',
      transaction: TransferTransaction.fromJson(json['transaction']),
    );
  }
}

class TransferTransaction {
  final String id;
  final String type;
  final String status;

  TransferTransaction({
    required this.id,
    required this.type,
    required this.status,
  });

  factory TransferTransaction.fromJson(Map<String, dynamic> json) {
    return TransferTransaction(
      id: json['_id'] ?? json['id'] ?? '',
      type: json['type'] ?? 'TRANSFER',
      status: json['status'] ?? 'pending',
    );
  }
}