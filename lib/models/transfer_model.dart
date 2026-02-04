class Transfer {
  final String id;
  final String fromWarehouse;
  final String toWarehouse;
  final List<dynamic> items;
  final String status;
  final String createdAt;
  final String? approvedBy;
  final String? note;

  Transfer({
    required this.id,
    required this.fromWarehouse,
    required this.toWarehouse,
    required this.items,
    required this.status,
    required this.createdAt,
    this.approvedBy,
    this.note,
  });

  factory Transfer.fromJson(Map<String, dynamic> json) {
    return Transfer(
      id: json['_id'] ?? '',
      fromWarehouse: json['fromWarehouse'] ?? '',
      toWarehouse: json['toWarehouse'] ?? '',
      items: json['items'] ?? [],
      status: json['status'] ?? '',
      createdAt: json['createdAt'] ?? '',
      approvedBy: json['approvedBy'],
      note: json['note'],
    );
  }
}