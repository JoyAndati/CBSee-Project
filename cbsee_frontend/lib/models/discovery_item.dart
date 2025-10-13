// lib/models/discovery_item.dart

class DiscoveryItem {
  final int id;
  final String name;
  final String imageUrl;
  final String category;
  final DateTime discoveredDate;

  DiscoveryItem({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.category,
    required this.discoveredDate,
  });

  // --- ADD THIS FACTORY CONSTRUCTOR ---
  factory DiscoveryItem.fromJson(Map<String, dynamic> json) {
    return DiscoveryItem(
      id: json['id'],
      name: json['name'] ?? 'Unknown',
      imageUrl: json['imageUrl'] ?? 'assets/images/history.png', // Handle potential null URLs
      category: json['category'] ?? 'General',
      discoveredDate: DateTime.parse(json['discoveredDate']),
    );
  }
}