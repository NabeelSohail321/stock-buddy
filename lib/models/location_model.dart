class Location {
  final String id;
  final String name;
  final String? address;
  final bool isActive;
  final String? createdByName;

  Location({
    required this.id,
    required this.name,
    this.address,
    required this.isActive,
    this.createdByName,
  });

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      id: json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unknown Location',
      address: json['address']?.toString(),
      isActive: json['isActive'] is bool ? json['isActive'] : true,
      createdByName: json['createdBy'] is Map
          ? json['createdBy']['name']?.toString()
          : null,
    );
  }
}