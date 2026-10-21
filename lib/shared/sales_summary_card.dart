import 'package:flutter/material.dart';

/// Shows today's total sales and number of transactions.
/// Place this file in: lib/widgets/sales_summary_card.dart
class SalesSummaryCard extends StatelessWidget {
  final double totalSales;
  final int transactionCount;

  const SalesSummaryCard({
    super.key,
    required this.totalSales,
    required this.transactionCount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _statBox(
            icon: Icons.payments_rounded,
            label: "Today's Sales",
            value: '₱${totalSales.toStringAsFixed(2)}',
            color: Colors.greenAccent,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _statBox(
            icon: Icons.receipt_long_rounded,
            label: 'Transactions Today',
            value: '$transactionCount',
            color: Colors.lightBlueAccent,
          ),
        ),
      ],
    );
  }

  Widget _statBox({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0x990F4C75),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}