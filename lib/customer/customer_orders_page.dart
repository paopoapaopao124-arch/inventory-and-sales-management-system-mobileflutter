
import 'package:flutter/material.dart';

import '../models/sale_transaction.dart';
import '../services/api_service.dart';
import '../shared/app_theme.dart';

class CustomerOrdersPage extends StatefulWidget {
  const CustomerOrdersPage({super.key});

  @override
  State<CustomerOrdersPage> createState() => _CustomerOrdersPageState();
}

class _CustomerOrdersPageState extends State<CustomerOrdersPage> {
  late Future<List<SaleTransaction>> _ordersFuture;

  @override
  void initState() {
    super.initState();
    _ordersFuture = _loadOrders();
  }

  Future<List<SaleTransaction>> _loadOrders() async {
    final sales = await ApiService.fetchSales();
    return sales
        .map((sale) => SaleTransaction.fromJson(Map<String, dynamic>.from(sale as Map)))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.navy,
      appBar: AppBar(
        title: const Text('My Orders'),
        backgroundColor: AppTheme.navy,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back to Home',
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: FutureBuilder<List<SaleTransaction>>(
        future: _ordersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Unable to load your orders: ${snapshot.error}'),
              ),
            );
          }

          final transactions = snapshot.data ?? const <SaleTransaction>[];

          if (transactions.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.receipt_long_outlined,
                      size: 65,
                      color: AppTheme.emerald,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No Orders Yet',
                      style: TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Your recorded purchases will appear here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppTheme.muted),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF087B64),
                      AppTheme.emerald,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Recorded Purchases',
                      style: TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${transactions.length} transaction(s)',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              ...transactions.map((sale) => _OrderCard(sale: sale)),
            ],
          );
        },
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final SaleTransaction sale;

  const _OrderCard({required this.sale});

  @override
  Widget build(BuildContext context) {
    final date = sale.date;
    final dateText =
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.day.toString().padLeft(2, '0')}/'
        '${date.year}';

    final timeText =
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';

    return Card(
      color: AppTheme.card,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ExpansionTile(
        iconColor: AppTheme.emerald,
        collapsedIconColor: AppTheme.muted,
        leading: const CircleAvatar(
          backgroundColor: Color(0xFF103D4C),
          child: Icon(
            Icons.receipt_long,
            color: AppTheme.emerald,
          ),
        ),
        title: Text(
          'Order ${sale.id}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('$dateText • $timeText'),
        trailing: const Icon(Icons.keyboard_arrow_down),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          const Divider(color: Colors.white12),
          ...sale.items.map(
                (item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${item.productName} × ${item.quantity}',
                    ),
                  ),
                  Text(
                    '₱${item.subtotal.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: AppTheme.emerald,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(color: Colors.white12),
          _detailRow('Payment Method', sale.paymentMethod),
          const SizedBox(height: 8),
          _detailRow(
            'Total',
            '₱${sale.total.toStringAsFixed(2)}',
            bold: true,
          ),
          const SizedBox(height: 12),
          const Row(
            children: [
              Icon(
                Icons.check_circle,
                color: AppTheme.emerald,
                size: 18,
              ),
              SizedBox(width: 8),
              Text(
                'Recorded in this app',
                style: TextStyle(color: AppTheme.emerald),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _detailRow(
      String label,
      String value, {
        bool bold = false,
      }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: AppTheme.muted),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            color: bold ? AppTheme.emerald : Colors.white,
            fontSize: bold ? 17 : 14,
          ),
        ),
      ],
    );
  }
}
