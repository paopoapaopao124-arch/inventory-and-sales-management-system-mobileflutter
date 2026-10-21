
import 'package:flutter/material.dart';

import '../data/store_data.dart';
import '../shared/app_theme.dart';
import 'e_receipt_page.dart';

class TransactionHistoryPage extends StatelessWidget {
  const TransactionHistoryPage({super.key});

  String money(double amount) => '₱${amount.toStringAsFixed(2)}';

  String formatDate(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    final y = date.year.toString();
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';

    return '$m/$d/$y • $hour:$minute $period';
  }

  Future<void> confirmVoid(
      BuildContext context,
      String transactionId,
      ) async {
    final shouldVoid = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Void Transaction?'),
        content: const Text(
          'Are you sure you want to void this transaction? '
              'The sold products should be returned to stock, '
              'and the sale will no longer count toward total sales.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Confirm Void'),
          ),
        ],
      ),
    );

    if (shouldVoid != true) return;

    try {
      await StoreData.instance.voidTransaction(transactionId);

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Transaction voided successfully.'),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to void transaction: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction History'),
      ),
      body: AnimatedBuilder(
        animation: StoreData.instance,
        builder: (context, child) {
          final transactions =
          StoreData.instance.transactions.reversed.toList();

          final activeTransactions =
          transactions.where((sale) => !sale.isVoided).toList();

          final total = activeTransactions.fold<double>(
            0.0,
                (sum, sale) => sum + sale.total,
          );

          if (transactions.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.receipt_long_outlined,
                      size: 72,
                      color: AppTheme.muted,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No transactions yet',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Completed checkout sales will appear here.',
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
              Card(
                color: AppTheme.card,
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TOTAL VALID SALES',
                        style: TextStyle(
                          color: AppTheme.muted,
                          fontSize: 12,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        money(total),
                        style: TextStyle(
                          color: AppTheme.emerald,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${activeTransactions.length} valid transaction(s)',
                        style: TextStyle(color: AppTheme.muted),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'RECENT TRANSACTIONS',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 10),

              ...transactions.map(
                    (sale) => Card(
                  color: AppTheme.card,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    children: [
                      ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                          sale.isVoided
                              ? Colors.red.withValues(alpha: 0.15)
                              : AppTheme.emerald.withValues(alpha: 0.15),
                          child: Icon(
                            sale.isVoided
                                ? Icons.block
                                : Icons.receipt_long,
                            color: sale.isVoided
                                ? Colors.red
                                : AppTheme.emerald,
                          ),
                        ),
                        title: Text(
                          'Receipt #${sale.id.substring(sale.id.length > 6 ? sale.id.length - 6 : 0)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 5),
                          child: Text(
                            '${formatDate(sale.date)}\n'
                                '${sale.items.length} product type(s) • '
                                '${sale.paymentMethod}',
                            style: TextStyle(color: AppTheme.muted),
                          ),
                        ),
                        isThreeLine: true,
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              money(sale.total),
                              style: TextStyle(
                                color: sale.isVoided
                                    ? Colors.red
                                    : AppTheme.emerald,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              sale.isVoided ? 'VOIDED' : 'COMPLETED',
                              style: TextStyle(
                                color: sale.isVoided
                                    ? Colors.red
                                    : AppTheme.emerald,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  EReceiptPage(transaction: sale),
                            ),
                          );
                        },
                      ),


          // Void button appears only for valid transactions.
          if (!sale.isVoided)
          Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
          child: Align(
          alignment: Alignment.centerRight,
          child: OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
          foregroundColor: Colors.red,
          side: const BorderSide(color: Colors.red),
          ),
          icon: const Icon(Icons.block),
          label: const Text('Void Transaction'),
          onPressed: () => confirmVoid(context, sale.id),
          ),
          ),
          )

        else
                        const Padding(
                          padding: EdgeInsets.only(bottom: 12),
                          child: Text(
                            'This transaction has been voided.',
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
