class ManagerNotificationPreferences {
  final bool stock;
  final bool repair;
  final bool disposal;
  final bool transfer;

  ManagerNotificationPreferences({
    this.stock = true,
    this.repair = true,
    this.disposal = true,
    this.transfer = true,
  });

  factory ManagerNotificationPreferences.fromJson(Map<String, dynamic> json) {
    return ManagerNotificationPreferences(
      stock: json['stock'] ?? true,
      repair: json['repair'] ?? true,
      disposal: json['disposal'] ?? true,
      transfer: json['transfer'] ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'stock': stock,
        'repair': repair,
        'disposal': disposal,
        'transfer': transfer,
      };
}

class Manager {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final List<String> assignedLocationIds;
  final List<String> assignedLocationNames;
  final ManagerNotificationPreferences notificationPreferences;
  final bool isActive;

  Manager({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.assignedLocationIds,
    this.assignedLocationNames = const [],
    required this.notificationPreferences,
    this.isActive = true,
  });

  factory Manager.fromJson(Map<String, dynamic> json) {
    List<String> locationIds = [];
    List<String> locationNames = [];

    final rawLocations = json['assignedLocationIds'];
    if (rawLocations is List) {
      for (final loc in rawLocations) {
        if (loc is String) {
          locationIds.add(loc);
        } else if (loc is Map) {
          locationIds.add(loc['_id']?.toString() ?? '');
          locationNames.add(loc['name']?.toString() ?? '');
        }
      }
    }

    return Manager(
      id: json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unknown',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString(),
      assignedLocationIds: locationIds,
      assignedLocationNames: locationNames,
      notificationPreferences: json['notificationPreferences'] != null
          ? ManagerNotificationPreferences.fromJson(json['notificationPreferences'])
          : ManagerNotificationPreferences(),
      isActive: json['isActive'] ?? true,
    );
  }
}
