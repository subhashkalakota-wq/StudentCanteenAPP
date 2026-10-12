class MenuItemModel {
  final String id;
  final String name;
  final double price;
  final String description;
  final bool isVeg;
  final String categoryId;
  final String categoryName;
  final String imageUrl;
  final bool isAvailable;

  MenuItemModel({
    required this.id,
    required this.name,
    required this.price,
    required this.description,
    required this.isVeg,
    required this.categoryId,
    required this.categoryName,
    required this.imageUrl,
    this.isAvailable = true,
  });

  factory MenuItemModel.fromJson(Map<String, dynamic> json) {
    return MenuItemModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      description: json['description'] ?? '',
      isVeg: json['isVeg'] ?? true,
      categoryId: json['categoryId'] ?? 'ALL',
      categoryName: json['categoryName'] ?? 'General',
      imageUrl: json['imageUrl'] ?? 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=600&auto=format&fit=crop&q=80',
      isAvailable: json['isAvailable'] ?? true,
    );
  }
}
