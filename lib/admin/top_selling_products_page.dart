
import 'package:flutter/material.dart';

import '../data/store_data.dart';
import '../shared/app_theme.dart';

class TopSellingProductsPage extends StatelessWidget {
  const TopSellingProductsPage({super.key});

  String money(double amount) => '₱${amount.toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Top Selling Products'),
      ),
      body: AnimatedBuilder(
        animation: StoreData.instance,
        builder: (context, child) {
          final transactions = StoreData.instance.transactions
              .where((sale) => !sale.isVoided)
              .toList();

          // Count sold quantities and sales amount per product.
          final Map<String, Map<String, dynamic>> productTotals = {};

          for (final sale in transactions) {
            for (final item in sale.items) {
              final data = productTotals.putIfAbsent(
                item.productId,
                    () => {
                  'name': item.productName,
                  'quantity': 0,
                  'revenue': 0.0,
                },
              );

              data['quantity'] =
                  (data['quantity'] as int) + item.quantity;

              data['revenue'] =
                  (data['revenue'] as double) + item.subtotal;
            }
          }

          final rankings = productTotals.entries.toList()
            ..sort((a, b) {
              final aQty = a.value['quantity'] as int;
              final bQty = b.value['quantity'] as int;
              return bQty.compareTo(aQty);
            });

          if (rankings.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.trending_up_rounded,
                      size: 72,
                      color: AppTheme.muted,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No Sales Data Yet',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Top-selling products will appear after '
                          'completed checkout transactions.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppTheme.muted),
                    ),
                  ],
                ),
              ),
            );
          }

          final totalUnitsSold = rankings.fold<int>(
            0,
                (sum, entry) =>
            sum + (entry.value['quantity'] as int),
          );

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                color: AppTheme.card,
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.emoji_events_rounded,
                        color: AppTheme.emerald,
                        size: 42,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'TOTAL ITEMS SOLD',
                              style: TextStyle(
                                color: AppTheme.muted,
                                fontSize: 12,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '$totalUnitsSold units',
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.emerald,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 22),
              const Text(
                'PRODUCT RANKINGS',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 12),

              ...List.generate(rankings.length, (index) {
                final entry = rankings[index];
                final name = entry.value['name'] as String;
                final quantity = entry.value['quantity'] as int;
                final revenue = entry.value['revenue'] as double;

                final rankColor = index == 0
                    ? AppTheme.emerald
                    : index == 1
                    ? Colors.blue
                    : index == 2
                    ? Colors.orange
                    : AppTheme.muted;

                return Card(
                  color: AppTheme.card,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: rankColor.withValues(alpha: 0.15),
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: rankColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        '$quantity units sold',
                        style: TextStyle(color: AppTheme.muted),
                      ),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          money(revenue),
                          style: const TextStyle(
                            color: AppTheme.emerald,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Sales amount',
                          style: TextStyle(
                            color: AppTheme.muted,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}
