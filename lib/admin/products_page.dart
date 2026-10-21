import 'dart:convert';

import 'package:flutter/material.dart';

import '../data/store_data.dart';
import '../models/product.dart';
import '../shared/app_theme.dart';
import 'product_form_page.dart';

// Dark palette, same look as the Quick Actions cards.
const Color _accent = AppTheme.emerald;
const Color _ink = Colors.white;
const Color _gray = AppTheme.muted;
const Color _line = Color(0xFF24516B);
const Color _green = AppTheme.emerald;
const Color _red = AppTheme.danger;

class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key, this.embedded = false});

  /// true = shown inside the admin dashboard (no own Scaffold/AppBar)
  final bool embedded;

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _addProduct() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => const ProductFormPage(),
      ),
    );

    if (!mounted) return;

    if (result == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Product added successfully!'),
          backgroundColor: AppTheme.emerald,
        ),
      );
    }
  }

  List<Product> _filtered(List<Product> products) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return products;

    return products.where((p) {
      return p.name.toLowerCase().contains(q) ||
          p.brand.toLowerCase().contains(q) ||
          p.category.toLowerCase().contains(q) ||
          p.description.toLowerCase().contains(q) ||
          p.barcode.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final store = StoreData.instance;

    final body = AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        if (!store.isLoaded) {
          return const Center(child: CircularProgressIndicator());
        }

        final products = _filtered(store.products);

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // HEADER
            const Text(
              'Product Records',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'View, search, edit, and manage your inventory',
              style: TextStyle(color: AppTheme.muted, fontSize: 13),
            ),
            const SizedBox(height: 16),

            // SEARCH + ADD PRODUCT
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(() => _query = value),
                    style: const TextStyle(color: _ink),
                    decoration: InputDecoration(
                      hintText:
                      'Search brands, products, categories, or descriptions...',
                      hintStyle: const TextStyle(color: _gray, fontSize: 13),
                      prefixIcon: const Icon(Icons.search, color: _gray),
                      suffixIcon: _query.isEmpty
                          ? null
                          : IconButton(
                        icon: const Icon(Icons.close, color: _gray),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      ),
                      filled: true,
                      fillColor: AppTheme.card,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 16,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: _line),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: _accent),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: _line),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accent,
                    foregroundColor: AppTheme.navy,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 18,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _addProduct,
                  icon: const Icon(Icons.add),
                  label: const Text(
                    'Add Product',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (store.products.isEmpty)
              _emptyState(
                icon: Icons.inventory_2_outlined,
                message: 'No products yet.',
                showAdd: true,
              )
            else if (products.isEmpty)
              _emptyState(
                icon: Icons.search_off,
                message: 'No products match your search.',
              )
            else ...[
                Text(
                  '${products.length} of ${store.productCount} Products',
                  style: const TextStyle(color: AppTheme.muted, fontSize: 13),
                ),
                const SizedBox(height: 8),
                ProductRecordsTable(products: products),
              ],
          ],
        );
      },
    );

    if (widget.embedded) return body;

    return Scaffold(
      backgroundColor: AppTheme.navy,
      appBar: AppBar(title: const Text('Product Records')),
      body: body,
    );
  }

  Widget _emptyState({
    required IconData icon,
    required String message,
    bool showAdd = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(icon, size: 64, color: AppTheme.muted),
          const SizedBox(height: 12),
          Text(message, style: const TextStyle(color: AppTheme.muted)),
          if (showAdd) ...[
            const SizedBox(height: 12),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: AppTheme.navy,
              ),
              onPressed: _addProduct,
              icon: const Icon(Icons.add),
              label: const Text('Add Your First Product'),
            ),
          ],
        ],
      ),
    );
  }
}

/// The "Product Records" table. Used by the Products tab AND the Home tab,
/// so both always look the same.
///
/// BRAND | PRODUCT NAME | CATEGORY | PRICE | QUANTITY | STATUS |
/// DESCRIPTION | ACTIONS
class ProductRecordsTable extends StatelessWidget {
  const ProductRecordsTable({super.key, required this.products});

  final List<Product> products;

  Future<void> _edit(BuildContext context, Product product) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => ProductFormPage(product: product),
      ),
    );

    if (!context.mounted) return;

    if (result == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Product updated successfully!'),
          backgroundColor: AppTheme.emerald,
        ),
      );
    }
  }

  Future<void> _delete(BuildContext context, Product product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.card,
        title: const Text('Delete Product?'),
        content: Text('Are you sure you want to delete "${product.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(
              'Delete',
              style: TextStyle(color: AppTheme.danger),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    await StoreData.instance.deleteProduct(product.id);

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Product deleted successfully!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    const headStyle = TextStyle(
      color: _accent,
      fontSize: 12,
      fontWeight: FontWeight.w800,
      letterSpacing: 0.8,
    );

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _line),
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingTextStyle: headStyle,
          headingRowColor:
          WidgetStatePropertyAll(Colors.white.withValues(alpha: 0.04)),
          dividerThickness: 1,
          dataRowMinHeight: 84,
          dataRowMaxHeight: double.infinity,
          columnSpacing: 32,
          columns: const [
            DataColumn(label: Text('BRAND')),
            DataColumn(label: Text('PRODUCT NAME')),
            DataColumn(label: Text('CATEGORY')),
            DataColumn(label: Text('PRICE')),
            DataColumn(label: Text('QUANTITY')),
            DataColumn(label: Text('STATUS')),
            DataColumn(label: Text('DESCRIPTION')),
            DataColumn(label: Text('ACTIONS')),
          ],
          rows: products.map((p) => _row(context, p)).toList(),
        ),
      ),
    );
  }

  DataRow _row(BuildContext context, Product product) {
    final Color statusColor = product.isOutOfStock
        ? _red
        : product.isLowStock
        ? Colors.orange
        : _green;

    final String status = product.isOutOfStock
        ? 'Out of Stock'
        : product.isLowStock
        ? 'Low Stock'
        : 'In Stock';

    return DataRow(
      cells: [
        // BRAND
        DataCell(
          Text(
            product.brand.trim().isEmpty ? '-' : product.brand,
            style: const TextStyle(
              color: _accent,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        // PRODUCT NAME + IMAGE
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: _accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _line),
                ),
                clipBehavior: Clip.antiAlias,
                child: _image(product),
              ),
              const SizedBox(width: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 170),
                child: Text(
                  product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),

        // CATEGORY
        DataCell(
          Text(
            product.category.trim().isEmpty ? '-' : product.category,
            style: const TextStyle(
              color: _accent,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        // PRICE
        DataCell(
          Text(
            '₱${product.price.toStringAsFixed(2)}',
            style: const TextStyle(
              color: _ink,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        // QUANTITY
        DataCell(
          Text(
            '${product.stock}',
            style: const TextStyle(
              color: _ink,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        // STATUS
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.circle, size: 8, color: statusColor),
                const SizedBox(width: 6),
                Text(
                  status,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),

        // DESCRIPTION (full text, wraps to many lines)
        DataCell(
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 260),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                product.description.trim().isEmpty
                    ? '-'
                    : product.description,
                style: const TextStyle(
                  color: _gray,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ),

        // ACTIONS
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton.icon(
                style: TextButton.styleFrom(foregroundColor: _accent),
                onPressed: () => _edit(context, product),
                icon: const Icon(Icons.edit_rounded, size: 16),
                label: const Text(
                  'Edit',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              TextButton.icon(
                style: TextButton.styleFrom(foregroundColor: _red),
                onPressed: () => _delete(context, product),
                icon: const Icon(Icons.delete_rounded, size: 16),
                label: const Text(
                  'Delete',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _image(Product product) {
    final imageData = product.imageUrl.trim();

    if (imageData.isEmpty) {
      // No uploaded picture: show the product emoji instead.
      return Center(
        child: Text(product.emoji, style: const TextStyle(fontSize: 26)),
      );
    }

    try {
      final commaIndex = imageData.indexOf(',');

      final encodedImage =
      imageData.startsWith('data:image/') && commaIndex != -1
          ? imageData.substring(commaIndex + 1)
          : imageData;

      return Image.memory(
        base64Decode(encodedImage),
        width: 52,
        height: 52,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
        const Icon(Icons.broken_image_outlined, size: 26, color: _gray),
      );
    } catch (_) {
      return const Icon(Icons.broken_image_outlined, size: 26, color: _gray);
    }
  }
}