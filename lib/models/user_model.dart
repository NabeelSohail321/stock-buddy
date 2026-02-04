import 'dart:convert';

class User {
  final String id;
  final String email;
  final String name;
  final String role;
  final DateTime? lastLogin;

  User({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.lastLogin,
  });

  /// ✅ Factory constructor to create a User from JSON
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      role: json['role']?.toString() ?? 'user',
      lastLogin: json['lastLogin'] != null
          ? DateTime.tryParse(json['lastLogin'].toString())
          : null,
    );
  }

  /// ✅ Convert a User object to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role,
      'lastLogin': lastLogin?.toIso8601String(),
    };
  }

  /// ✅ copyWith method for immutability and convenience
  User copyWith({
    String? id,
    String? email,
    String? name,
    String? role,
    DateTime? lastLogin,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      lastLogin: lastLogin ?? this.lastLogin,
    );
  }
}
