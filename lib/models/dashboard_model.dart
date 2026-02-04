import 'package:flutter/material.dart';

class DashboardData {
  final DashboardSummary summary;
  final List<LowStockItem> lowStockItems;
  final List<dynamic> recentTransactions;

  DashboardData({
    required this.summary,
    required this.lowStockItems,
    required this.recentTransactions,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    return DashboardData(
      summary: DashboardSummary.fromJson(json['summary']),
      lowStockItems: (json['lowStockItems'] as List)
          .map((item) => LowStockItem.fromJson(item))
          .toList(),
      recentTransactions: json['recentTransactions'] as List,
    );
  }
}

class DashboardSummary {
  final int totalItems;
  final int totalStock;
  final int lowStockCount;
  final int pendingRepairs;
  final int pendingDisposals;

  DashboardSummary({
    required this.totalItems,
    required this.totalStock,
    required this.lowStockCount,
    required this.pendingRepairs,
    required this.pendingDisposals,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    return DashboardSummary(
      totalItems: json['totalItems'] ?? 0,
      totalStock: json['totalStock'] ?? 0,
      lowStockCount: json['lowStockCount'] ?? 0,
      pendingRepairs: json['pendingRepairs'] ?? 0,
      pendingDisposals: json['pendingDisposals'] ?? 0,
    );
  }
}

class LowStockItem {
  final String id;
  final String name;
  final String sku;
  final int currentStock;
  final int threshold;

  LowStockItem({
    required this.id,
    required this.name,
    required this.sku,
    required this.currentStock,
    required this.threshold,
  });

  factory LowStockItem.fromJson(Map<String, dynamic> json) {
    return LowStockItem(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unknown Item',
      sku: json['sku']?.toString() ?? '',
      currentStock: json['currentStock'] is int ? json['currentStock'] : int.tryParse(json['currentStock']?.toString() ?? '0') ?? 0,
      threshold: json['threshold'] is int ? json['threshold'] : int.tryParse(json['threshold']?.toString() ?? '0') ?? 0,
    );
  }

  // Calculate how much below threshold the item is
  int get stockDeficit => threshold - currentStock;

  // Calculate percentage of threshold remaining
  double get stockPercentage => (currentStock / threshold) * 100;

  // Get stock status
  String get stockStatus {
    if (currentStock <= 0) return 'Out of Stock';
    if (currentStock < threshold * 0.25) return 'Critical';
    if (currentStock < threshold * 0.5) return 'Low';
    return 'Below Threshold';
  }

  Color get statusColor {
    switch (stockStatus) {
      case 'Out of Stock':
        return Colors.red;
      case 'Critical':
        return Colors.orange;
      case 'Low':
        return Colors.amber;
      default:
        return Colors.blue;
    }
  }
}