
import 'package:flutter/material.dart';

import '../data/store_data.dart';
import '../models/sale_transaction.dart';
import '../shared/app_theme.dart';

class SalesReportsPage extends StatelessWidget {
  const SalesReportsPage({super.key});

  String money(double amount) => '₱${amount.toStringAsFixed(2)}';

  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String shortDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales Reports'),
      ),
      body: AnimatedBuilder(
        animation: StoreData.instance,
        builder: (context, child) {
          final store = StoreData.instance;
          final transactions = store.transactions.reversed.toList();
          final now = DateTime.now();

          final todayTransactions = transactions
              .where((sale) => isSameDay(sale.date, now))
              .toList();

          final todayTotal = todayTransactions.fold<double>(
            0,
                (sum, sale) => sum + sale.total,
          );

          final last7Days = List.generate(7, (index) {
            final date = DateTime(now.year, now.month, now.day)
                .subtract(Duration(days: 6 - index));

            final dailyTotal = transactions
                .where((sale) => isSameDay(sale.date, date))
                .fold<double>(0, (sum, sale) => sum + sale.total);

            return _DailySales(date: date, total: dailyTotal);
          });

          final weeklyTotal = last7Days.fold<double>(
            0,
                (sum, day) => sum + day.total,
          );

          final maxDailySales = last7Days.fold<double>(
            0,
                (maximum, day) => day.total > maximum ? day.total : maximum,
          );

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Sales Overview',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Based on completed checkout transactions',
                style: TextStyle(color: AppTheme.muted),
              ),
              const SizedBox(height: 18),

              _ReportCard(
                title: "Today's Sales",
                amount: money(todayTotal),
                subtitle: '${todayTransactions.length} transaction(s) today',
                icon: Icons.today,
              ),
              const SizedBox(height: 12),

              _ReportCard(
                title: 'All-Time Sales',
                amount: money(store.totalSales),
                subtitle: '${store.transactionCount} completed transaction(s)',
                icon: Icons.payments_outlined,
              ),
              const SizedBox(height: 12),

              _ReportCard(
                title: 'Sales — Last 7 Days',
                amount: money(weeklyTotal),
                subtitle: 'From the last seven calendar days, including today',
                icon: Icons.calendar_month,
              ),
              const SizedBox(height: 24),

              Card(
                color: AppTheme.card,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'DAILY SALES BREAKDOWN',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 18),
                      ...last7Days.map((day) {
                        final barRatio = maxDailySales == 0
                            ? 0.0
                            : (day.total / maxDailySales).clamp(0.0, 1.0);

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(shortDate(day.date)),
                                  ),
                                  Text(
                                    money(day.total),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 7),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: LinearProgressIndicator(
                                  value: barRatio,
                                  minHeight: 9,
                                  backgroundColor: AppTheme.field,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppTheme.emerald,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              const Text(
                'RECENT SALES',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 10),

              if (transactions.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 28),
                  child: Column(
                    children: [
                      Icon(
                        Icons.bar_chart,
                        size: 52,
                        color: AppTheme.muted,
                      ),
                      const SizedBox(height: 10),
                      const Text('No sales recorded yet'),
                      const SizedBox(height: 5),
                      Text(
                        'Complete a checkout transaction to populate this report.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppTheme.muted),
                      ),
                    ],
                  ),
                )
              else
                ...transactions.take(20).map(
                      (sale) => _RecentSaleTile(
                    sale: sale,
                    dateLabel: shortDate(sale.date),
                    money: money,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _DailySales {
  final DateTime date;
  final double total;

  const _DailySales({
    required this.date,
    required this.total,
  });
}

class _ReportCard extends StatelessWidget {
  final String title;
  final String amount;
  final String subtitle;
  final IconData icon;

  const _ReportCard({
    required this.title,
    required this.amount,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppTheme.card,
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: AppTheme.emerald.withValues(alpha: 0.13),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppTheme.emerald, size: 27),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(color: AppTheme.muted),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    amount,
                    style: TextStyle(
                      color: AppTheme.emerald,
                      fontSize: 23,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: AppTheme.muted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentSaleTile extends StatelessWidget {
  final SaleTransaction sale;
  final String dateLabel;
  final String Function(double) money;

  const _RecentSaleTile({
    required this.sale,
    required this.dateLabel,
    required this.money,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppTheme.card,
      child: ListTile(
        leading: Icon(
          Icons.receipt_long,
          color: AppTheme.emerald,
        ),
        title: Text(dateLabel),
        subtitle: Text(
          '${sale.items.length} product type(s) • ${sale.paymentMethod}',
          style: TextStyle(color: AppTheme.muted),
        ),
        trailing: Text(
          money(sale.total),
          style: TextStyle(
            color: AppTheme.emerald,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
