
import 'package:flutter/material.dart';

import '../data/store_data.dart';
import '../models/product.dart';
import '../shared/app_theme.dart';

class LowStockNotificationsPage extends StatelessWidget {
  const LowStockNotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Low Stock Notifications'),
      ),
      body: AnimatedBuilder(
        animation: StoreData.instance,
        builder: (context, child) {
          final products = StoreData.instance.products;

          final lowStockProducts = products
              .where((product) => product.stock > 0 && product.stock <= 5)
              .toList()
            ..sort((a, b) => a.stock.compareTo(b.stock));

          final outOfStockProducts = products
              .where((product) => product.stock == 0)
              .toList();

          final needsRestock = [...outOfStockProducts, ...lowStockProducts];

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Inventory Alerts',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Monitor products that need restocking.',
                style: TextStyle(color: AppTheme.muted),
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: _AlertSummaryCard(
                      title: 'Low Stock',
                      count: lowStockProducts.length,
                      icon: Icons.inventory_2_outlined,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _AlertSummaryCard(
                      title: 'Out of Stock',
                      count: outOfStockProducts.length,
                      icon: Icons.remove_shopping_cart_outlined,
                      color: AppTheme.danger,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'PRODUCTS NEEDING ATTENTION',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  Text(
                    '${needsRestock.length} item(s)',
                    style: TextStyle(color: AppTheme.muted),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (needsRestock.isEmpty)
                Card(
                  color: AppTheme.card,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 58,
                          color: AppTheme.emerald,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'All products are sufficiently stocked!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'No products currently have five or fewer units.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppTheme.muted),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...needsRestock.map(
                      (product) => _StockAlertTile(product: product),
                ),

              const SizedBox(height: 20),
              Text(
                'Alert rule: low stock means 1–5 units. Out of stock means 0 units.',
                style: TextStyle(
                  color: AppTheme.muted,
                  fontSize: 12,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AlertSummaryCard extends StatelessWidget {
  final String title;
  final int count;
  final IconData icon;
  final Color color;

  const _AlertSummaryCard({
    required this.title,
    required this.count,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppTheme.card,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 12),
            Text(
              '$count',
              style: TextStyle(
                color: color,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(color: AppTheme.muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _StockAlertTile extends StatelessWidget {
  final Product product;

  const _StockAlertTile({required this.product});

  @override
  Widget build(BuildContext context) {
    final isOutOfStock = product.stock == 0;
    final alertColor = isOutOfStock ? AppTheme.danger : Colors.orange;

    return Card(
      color: AppTheme.card,
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: alertColor.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            product.emoji,
            style: const TextStyle(fontSize: 26),
          ),
        ),
        title: Text(
          product.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Text(
            isOutOfStock ? 'Restock required immediately' : 'Stock is running low',
            style: TextStyle(color: alertColor, fontSize: 12),
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${product.stock}',
              style: TextStyle(
                color: alertColor,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'left',
              style: TextStyle(color: AppTheme.muted, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
