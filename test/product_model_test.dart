import 'package:dark_system/models/product.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Product.fromJson accepts Laravel product payload', () {
    final product = Product.fromJson({
      'id': 12,
      'name': 'Smartphone',
      'price': 1500.00,
      'quantity': 8,
      'brand': 'Demo',
      'category': 'electronics',
      'description': 'Demo phone',
      'image': 'https://example.com/image.jpg',
    });

    expect(product.id, '12');
    expect(product.stock, 8);
    expect(product.imageUrl, 'https://example.com/image.jpg');
  });
}
