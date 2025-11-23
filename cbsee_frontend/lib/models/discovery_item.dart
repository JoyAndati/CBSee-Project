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

  factory DiscoveryItem.fromJson(Map<String, dynamic> json) {
    // Handle potential missing image from backend by generating a placeholder
    String img = json['imageUrl'] as String? ?? '';
    if (img.isEmpty) {
      final query = json['name'] ?? 'object';
      // Uses a placeholder avatar service based on the object name
      img = 'https://ui-avatars.com/api/?name=$query&background=random&size=200';
    }

    return DiscoveryItem(
      id: json['id'],
      name: json['name'] ?? 'Unknown',
      imageUrl: img,
      category: json['category'] ?? 'General',
      discoveredDate: DateTime.parse(json['discoveredDate']),
    );
  }
}