
import 'package:flutter/material.dart';

import '../data/store_data.dart';
import '../models/product.dart';
import '../shared/app_theme.dart';

class CustomerCheckoutPage extends StatefulWidget {
  final Map<String, int> quantities;

  const CustomerCheckoutPage({
    super.key,
    required this.quantities,
  });

  @override
  State<CustomerCheckoutPage> createState() =>
      _CustomerCheckoutPageState();
}

class _CustomerCheckoutPageState
    extends State<CustomerCheckoutPage> {
  String paymentMethod = 'Cash';
  bool processing = false;

  double get orderTotal {
    double total = 0;

    for (final entry in widget.quantities.entries) {
      final matches = StoreData.instance.products
          .where((p) => p.id == entry.key);

      if (matches.isNotEmpty) {
        total += matches.first.price * entry.value;
      }
    }

    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.navy,
      appBar: AppBar(
        title: const Text('Checkout'),
        backgroundColor: AppTheme.navy,
      ),
      body: AnimatedBuilder(
        animation: StoreData.instance,
        builder: (context, _) {
          final store = StoreData.instance;

          return ListView(
            padding: const EdgeInsets.all(18),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.card,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.shopping_bag_outlined,
                      color: AppTheme.emerald,
                      size: 35,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Review Your Order',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Check the products and quantities before confirming.',
                      style: TextStyle(color: AppTheme.muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              ...widget.quantities.entries.map((entry) {
                final matches = store.products
                    .where((p) => p.id == entry.key);

                if (matches.isEmpty) {
                  return const SizedBox.shrink();
                }

                final Product product = matches.first;
                final quantity = entry.value;

                return Card(
                  color: AppTheme.card,
                  child: ListTile(
                    leading: Text(
                      product.emoji,
                      style: const TextStyle(fontSize: 30),
                    ),
                    title: Text(product.name),
                    subtitle: Text(
                      '$quantity × ₱${product.price.toStringAsFixed(2)}',
                    ),
                    trailing: Text(
                      '₱${(product.price * quantity).toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: AppTheme.emerald,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              }),

              const SizedBox(height: 20),
              const Text(
                'Payment Method',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),

              _paymentOption(
                title: 'Cash',
                subtitle: 'Pay with cash',
                icon: Icons.payments_outlined,
              ),
              const SizedBox(height: 8),

              _paymentOption(
                title: 'GCash',
                subtitle: 'Record GCash as the selected method',
                icon: Icons.phone_android,
              ),

              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.card,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total Amount',
                      style: TextStyle(color: AppTheme.muted),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '₱${orderTotal.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: AppTheme.emerald,
                        fontSize: 29,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 18),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed:
                        processing || widget.quantities.isEmpty
                            ? null
                            : _completeOrder,
                        icon: processing
                            ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                            : const Icon(
                          Icons.check_circle_outline,
                        ),
                        label: Text(
                          processing
                              ? 'Processing...'
                              : 'Confirm Order',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.emerald,
                          foregroundColor: AppTheme.navy,
                          padding: const EdgeInsets.all(16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _paymentOption({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final selected = paymentMethod == title;

    return InkWell(
      onTap: processing
          ? null
          : () => setState(() => paymentMethod = title),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? AppTheme.emerald
                : Colors.white12,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: AppTheme.emerald,
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppTheme.muted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_off,
              color: selected
                  ? AppTheme.emerald
                  : AppTheme.muted,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _completeOrder() async {
    if (processing || widget.quantities.isEmpty) return;

    setState(() => processing = true);

    final totalBeforeSale = orderTotal;
    final selectedPayment = paymentMethod;

    try {
      await StoreData.instance.completeSale(
        quantities: Map<String, int>.from(widget.quantities),
        paymentMethod: selectedPayment,
      );

      if (!mounted) return;

      // Display the success dialog while Checkout is still open.
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return AlertDialog(
            backgroundColor: AppTheme.card,
            icon: const Icon(
              Icons.check_circle,
              color: AppTheme.emerald,
              size: 55,
            ),
            title: const Text('Order Recorded!'),
            content: Text(
              'Your order total is '
                  '₱${totalBeforeSale.toStringAsFixed(2)}.\n\n'
                  'Payment method: $selectedPayment\n\n'
                  'The sale has been recorded in this app.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
                child: const Text('Done'),
              ),
            ],
          );
        },
      );

      if (!mounted) return;

      // Close Checkout and return to the previous dashboard.
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to complete order: $error'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => processing = false);
      }
    }
  }
}
