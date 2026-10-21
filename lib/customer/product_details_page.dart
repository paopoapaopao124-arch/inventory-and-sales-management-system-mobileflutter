import 'package:flutter/material.dart';

import '../models/product.dart';
import '../shared/app_theme.dart';

class ProductDetailsPage extends StatefulWidget {
  final Product product;
  final int initialCartCount;
  final int Function() onAddToCart;
  final VoidCallback? onOpenCart;

  const ProductDetailsPage({
    super.key,
    required this.product,
    required this.initialCartCount,
    required this.onAddToCart,
    this.onOpenCart,
  });

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  late int _cartCount;

  @override
  void initState() {
    super.initState();
    _cartCount = widget.initialCartCount;
  }

  void _handleAddToCart() {
    final nextCount = widget.onAddToCart();
    setState(() {
      _cartCount = nextCount;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${widget.product.name} added to cart.'),
        duration: const Duration(milliseconds: 900),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.navy,
      appBar: AppBar(
        backgroundColor: AppTheme.navy,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back to products',
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(widget.product.name),
        actions: [
          Badge(
            label: Text('$_cartCount'),
            isLabelVisible: _cartCount > 0,
            child: IconButton(
              tooltip: 'Open cart',
              icon: const Icon(Icons.shopping_cart_outlined),
              onPressed: () {
                if (widget.onOpenCart != null) {
                  widget.onOpenCart!();
                  Navigator.of(context).pop();
                  return;
                }

                _handleAddToCart();
              },
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: widget.product.imageUrl.isNotEmpty
                  ? Image.network(
                      widget.product.imageUrl,
                      width: double.infinity,
                      height: 280,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: double.infinity,
                          height: 280,
                          color: AppTheme.card,
                          child: Center(
                            child: Text(
                              widget.product.emoji,
                              style: const TextStyle(fontSize: 72),
                            ),
                          ),
                        );
                      },
                    )
                  : Container(
                      width: double.infinity,
                      height: 280,
                      color: AppTheme.card,
                      child: Center(
                        child: Text(
                          widget.product.emoji,
                          style: const TextStyle(fontSize: 72),
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 22),
            Text(
              widget.product.name,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '₱${widget.product.price.toStringAsFixed(2)}',
              style: const TextStyle(
                color: AppTheme.emerald,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _InfoChip(label: 'Category', value: widget.product.category.isNotEmpty ? widget.product.category : 'General'),
                const SizedBox(width: 8),
                _InfoChip(label: 'Brand', value: widget.product.brand.isNotEmpty ? widget.product.brand : 'N/A'),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.card,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.inventory_2_outlined, color: AppTheme.emerald),
                  const SizedBox(width: 10),
                  Text(
                    widget.product.stock > 0 ? 'In stock: ${widget.product.stock}' : 'Out of stock',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _handleAddToCart,
                icon: const Icon(Icons.add_shopping_cart),
                label: const Text('Add to Cart'),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Description',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.product.description.isNotEmpty
                  ? widget.product.description
                  : 'No description available for this product.',
              style: const TextStyle(
                color: AppTheme.muted,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;

  const _InfoChip({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(999),
      ),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: Colors.white),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(color: AppTheme.muted),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
