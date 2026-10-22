
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
  String _selectedFilter = 'all';

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

  Future<void> _refreshOrders() async {
    setState(() {
      _ordersFuture = _loadOrders();
    });
    await _ordersFuture;
  }

  List<SaleTransaction> _filterTransactions(List<SaleTransaction> transactions) {
    final filtered = <SaleTransaction>[];

    for (final transaction in transactions) {
      final normalizedStatus = transaction.status == 'completed'
          ? 'confirmed'
          : transaction.status;

      switch (_selectedFilter) {
        case 'pending':
          if (normalizedStatus == 'pending') {
            filtered.add(transaction);
          }
          break;
        case 'confirmed':
          if (normalizedStatus == 'confirmed') {
            filtered.add(transaction);
          }
          break;
        case 'voided':
          if (normalizedStatus == 'voided') {
            filtered.add(transaction);
          }
          break;
        case 'all':
        default:
          filtered.add(transaction);
          break;
      }
    }

    filtered.sort((a, b) {
      final normalizedA = a.status == 'completed' ? 'confirmed' : a.status;
      final normalizedB = b.status == 'completed' ? 'confirmed' : b.status;
      final order = <String, int>{
        'pending': 0,
        'confirmed': 1,
        'voided': 2,
      };

      final statusComparison = (order[normalizedA] ?? 99).compareTo(order[normalizedB] ?? 99);
      if (statusComparison != 0) {
        return statusComparison;
      }

      return b.date.compareTo(a.date);
    });

    return filtered;
  }

  final List<Map<String, String>> _statusFilters = const [
    {'label': 'All', 'value': 'all'},
    {'label': 'Pending', 'value': 'pending'},
    {'label': 'Confirmed', 'value': 'confirmed'},
    {'label': 'Void', 'value': 'voided'},
  ];

  String _tabLabel(String value) {
    switch (value) {
      case 'pending':
        return 'Pending';
      case 'confirmed':
        return 'Confirmed';
      case 'voided':
        return 'Void';
      case 'all':
      default:
        return 'All';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.navy,
      appBar: AppBar(
        title: const Text('My Orders'),
        backgroundColor: AppTheme.navy,
        automaticallyImplyLeading: false,
      ),
      body: RefreshIndicator(
        onRefresh: _refreshOrders,
        child: FutureBuilder<List<SaleTransaction>>(
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

            final transactions = _filterTransactions(snapshot.data ?? const <SaleTransaction>[]);

            if (snapshot.data == null) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (transactions.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.receipt_long_outlined,
                        size: 65,
                        color: AppTheme.emerald,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _selectedFilter == 'all' ? 'No Orders Yet' : 'No ${_tabLabel(_selectedFilter)} Orders',
                        style: const TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _selectedFilter == 'all'
                            ? 'Your recorded purchases will appear here.'
                            : 'There are no ${_tabLabel(_selectedFilter).toLowerCase()} orders at the moment.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppTheme.muted),
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
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _statusFilters.map((filter) {
                      final isSelected = _selectedFilter == filter['value'];
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedFilter = filter['value'] as String),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected ? AppTheme.emerald : AppTheme.card,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: isSelected ? AppTheme.emerald : Colors.white12,
                              ),
                            ),
                            child: Text(
                              filter['label'] as String,
                              style: TextStyle(
                                color: isSelected ? AppTheme.navy : Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 18),
                ...transactions.map((sale) => _OrderCard(sale: sale)),
              ],
            );
          },
        ),
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
          _detailRow('Status', _statusText(sale.status)),
          const SizedBox(height: 8),
          _detailRow('Processed By', sale.processedBy.isNotEmpty ? sale.processedBy : 'Pending review'),
          const SizedBox(height: 8),
          _detailRow('Payment Method', sale.paymentMethod),
          const SizedBox(height: 8),
          _detailRow(
            'Total',
            '₱${sale.total.toStringAsFixed(2)}',
            bold: true,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                _statusIcon(sale.status),
                color: _statusColor(sale.status),
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                _statusMessage(sale.status),
                style: TextStyle(color: _statusColor(sale.status)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _statusText(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Pending';
      case 'voided':
        return 'Voided';
      case 'confirmed':
      case 'completed':
        return 'Confirmed';
      default:
        return 'Pending';
    }
  }

  IconData _statusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.pending_actions;
      case 'voided':
        return Icons.cancel_outlined;
      case 'confirmed':
      case 'completed':
        return Icons.check_circle;
      default:
        return Icons.pending_actions;
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFFFFB300);
      case 'voided':
        return const Color(0xFFE53935);
      case 'confirmed':
      case 'completed':
        return AppTheme.emerald;
      default:
        return AppTheme.emerald;
    }
  }

  String _statusMessage(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Waiting for confirmation';
      case 'voided':
        return 'Order was voided';
      case 'confirmed':
      case 'completed':
        return 'Confirmed by staff';
      default:
        return 'Waiting for confirmation';
    }
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
