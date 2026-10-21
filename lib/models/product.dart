
class Product {
  final String id;
  String name;
  double price;
  int stock;
  String barcode;
  String emoji;
  String description;
  String category;
  String brand;
  String imageUrl;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.stock,
    this.barcode = '',
    this.emoji = '📦',
    this.description = '',
    this.category = '',
    this.brand = '',
    this.imageUrl = '',
  });

  bool get isLowStock => stock > 0 && stock <= 5;

  bool get isOutOfStock => stock == 0;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'price': price,
    'stock': stock,
    'barcode': barcode,
    'emoji': emoji,
    'description': description,
    'category': category,
    'brand': brand,
    'imageUrl': imageUrl,
  };

  factory Product.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    final rawStock = json['quantity'] ?? json['stock'] ?? 0;

    return Product(
      id: rawId == null ? '' : rawId.toString(),
      name: (json['name'] as String?) ?? 'Unnamed product',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      stock: (rawStock as num?)?.toInt() ?? 0,
      barcode: json['barcode'] as String? ?? '',
      emoji: json['emoji'] as String? ?? '📦',
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? '',
      brand: json['brand'] as String? ?? '',
      imageUrl: (json['imageUrl'] ?? json['image'] ?? '') as String? ?? '',
    );
  }
}
