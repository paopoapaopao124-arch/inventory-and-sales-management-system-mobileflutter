
import 'package:flutter/material.dart';
import '../data/store_data.dart';
import '../models/product.dart';
import '../shared/app_theme.dart';

class StockOverviewPage extends StatefulWidget {
  const StockOverviewPage({super.key});

  @override
  State<StockOverviewPage> createState() => _StockOverviewPageState();
}

class _StockOverviewPageState extends State<StockOverviewPage> {
  String selectedFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final store = StoreData.instance;

    return Scaffold(
      appBar: AppBar(title: const Text('Stock Overview')),
      body: AnimatedBuilder(
        animation: store,
        builder: (context, _) {
          final filtered = store.products.where((product) {
            switch (selectedFilter) {
              case 'In Stock':
                return product.stock > 5;
              case 'Low Stock':
                return product.stock > 0 && product.stock <= 5;
              case 'Out of Stock':
                return product.stock == 0;
              default:
                return true;
            }
          }).toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  Expanded(
                    child: _summary(
                      'Products',
                      '${store.productCount}',
                      Icons.inventory_2_outlined,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _summary(
                      'Total Units',
                      '${store.totalUnits}',
                      Icons.warehouse_outlined,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 7,
                children: [
                  'All',
                  'In Stock',
                  'Low Stock',
                  'Out of Stock',
                ].map((filter) {
                  return ChoiceChip(
                    label: Text(filter),
                    selected: selectedFilter == filter,
                    selectedColor: AppTheme.emerald,
                    onSelected: (_) {
                      setState(() => selectedFilter = filter);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 18),
              if (filtered.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: Text('No products in this category.')),
                ),
              ...filtered.map(_productTile),
            ],
          );
        },
      ),
    );
  }

  Widget _summary(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.emerald),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(label, style: const TextStyle(color: AppTheme.muted)),
        ],
      ),
    );
  }

  Widget _productTile(Product product) {
    final isOut = product.stock == 0;
    final isLow = product.stock > 0 && product.stock <= 5;

    final status = isOut
        ? 'Out of Stock'
        : isLow
        ? 'Low Stock'
        : 'In Stock';

    final statusColor = isOut || isLow
        ? AppTheme.danger
        : AppTheme.emerald;

    return Card(
      color: AppTheme.card,
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Text(
          product.emoji,
          style: const TextStyle(fontSize: 30),
        ),
        title: Text(
          product.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (product.description
                .trim()
                .isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                product.description,
                style: const TextStyle(
                  color: AppTheme.muted,
                  fontSize: 12,
                ),
              ),
            ],
            const SizedBox(height: 4),
            Text(
              'Stock: ${product.stock}  •  ₱${product.price.toStringAsFixed(
                  2)}',
            ),
            if (product.barcode.isNotEmpty)
              Text(
                'Barcode: ${product.barcode}',
                style: const TextStyle(
                  color: AppTheme.muted,
                  fontSize: 11,
                ),
              ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 9,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            status,
            style: TextStyle(
              color: statusColor,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}