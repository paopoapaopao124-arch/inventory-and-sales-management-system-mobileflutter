import 'package:flutter/material.dart';

import '../data/store_data.dart';
import '../models/discount_calculator.dart';
import '../models/product.dart';
import '../models/sale_transaction.dart';
import '../shared/app_theme.dart';
import 'barcode_scanner_page.dart';
import 'e_receipt_page.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final Map<String, int> cart = {};

  final TextEditingController searchController = TextEditingController();

  String paymentMethod = 'Cash';
  bool processing = false;

  // Discount percentage selected by the user.
  double discountPercent = 0;

  // Original subtotal before discount.
  double get cartTotal {
    final store = StoreData.instance;
    double total = 0;

    for (final entry in cart.entries) {
      final products = store.products.where((p) => p.id == entry.key);

      if (products.isNotEmpty) {
        total += products.first.price * entry.value;
      }
    }

    return total;
  }

  // Amount deducted from the subtotal.
  double get discountAmount {
    return DiscountCalculator.calculateDiscount(
      subtotal: cartTotal,
      discountPercent: discountPercent,
    );
  }

  // Final amount payable after discount.
  double get finalTotal {
    return DiscountCalculator.calculateTotal(
      subtotal: cartTotal,
      discountPercent: discountPercent,
    );
  }

  // Returns true if the product was added to the cart.
  bool addProduct(Product product) {
    final quantity = cart[product.id] ?? 0;

    if (quantity >= product.stock) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Not enough stock for ${product.name}.',
          ),
        ),
      );
      return false;
    }

    setState(() {
      cart[product.id] = quantity + 1;
    });

    return true;
  }

  void removeProduct(Product product) {
    final quantity = cart[product.id] ?? 0;

    if (quantity == 0) return;

    setState(() {
      if (quantity == 1) {
        cart.remove(product.id);
      } else {
        cart[product.id] = quantity - 1;
      }
    });
  }

  // SCAN A BARCODE AND ADD THE PRODUCT TO THE CART
  Future<void> scanToCart() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => const BarcodeScannerPage(),
      ),
    );

    if (!mounted || result == null) return;

    final barcode = result.trim();
    final product = StoreData.instance.findByBarcode(barcode);

    if (product == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No product found for barcode: $barcode'),
        ),
      );
      return;
    }

    if (product.isOutOfStock) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${product.name} is out of stock.'),
        ),
      );
      return;
    }

    if (addProduct(product)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Added ${product.name} (x${cart[product.id]}) to cart',
          ),
          backgroundColor: AppTheme.emerald,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> finishSale() async {
    if (cart.isEmpty || processing) return;

    setState(() => processing = true);

    try {
      final SaleTransaction transaction =
      await StoreData.instance.completeSale(
        quantities: Map<String, int>.from(cart),
        paymentMethod: paymentMethod,
        discountAmount: discountAmount,
        discountType: discountPercent > 0
            ? '${discountPercent.toStringAsFixed(2)}%'
            : 'None',
      );

      if (!mounted) return;

      setState(() => cart.clear());

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => EReceiptPage(transaction: transaction),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Checkout failed: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => processing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = StoreData.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout / Sell'),
        actions: [
          IconButton(
            tooltip: 'Scan barcode',
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: scanToCart,
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: store,
        builder: (context, _) {
          return Column(
            children: [
              // PRODUCT SEARCH + SCAN
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: 'Find a product by name or barcode',
                    suffixIcon: IconButton(
                      tooltip: 'Scan barcode',
                      icon: const Icon(
                        Icons.qr_code_scanner,
                        color: AppTheme.emerald,
                      ),
                      onPressed: scanToCart,
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),

              // PRODUCT LIST
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: store.products.where((product) {
                    final query = searchController.text.toLowerCase();

                    return product.name.toLowerCase().contains(query) ||
                        product.barcode.toLowerCase().contains(query);
                  }).map((product) {
                    return Card(
                      color: AppTheme.card,
                      child: ListTile(
                        leading: Text(
                          product.emoji,
                          style: const TextStyle(fontSize: 28),
                        ),
                        title: Text(product.name),
                        subtitle: Text(
                          '₱${product.price.toStringAsFixed(2)}'
                              ' · Stock ${product.stock}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: () => removeProduct(product),
                              icon: const Icon(
                                Icons.remove_circle_outline,
                              ),
                            ),
                            Text('${cart[product.id] ?? 0}'),
                            IconButton(
                              onPressed: product.stock == 0
                                  ? null
                                  : () => addProduct(product),
                              icon: const Icon(
                                Icons.add_circle,
                                color: AppTheme.emerald,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              // CHECKOUT SUMMARY
              Container(
                padding: const EdgeInsets.all(18),
                decoration: const BoxDecoration(
                  color: AppTheme.card,
                  border: Border(
                    top: BorderSide(
                      color: Color(0xFF24516B),
                    ),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // SUBTOTAL
                      _summaryRow(
                        'Subtotal',
                        '₱${cartTotal.toStringAsFixed(2)}',
                      ),

                      const SizedBox(height: 10),

                      // DISCOUNT INPUT
                      TextFormField(
                        key: const ValueKey('discount_percent'),
                        initialValue: discountPercent.toStringAsFixed(0),
                        keyboardType:
                        const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Discount (%)',
                          prefixIcon: Icon(Icons.discount_outlined),
                          suffixText: '%',
                          helperText: 'Enter a percentage from 0 to 100',
                        ),
                        onChanged: (value) {
                          final parsed = double.tryParse(value) ?? 0;

                          setState(() {
                            discountPercent =
                                parsed.clamp(0.0, 100.0).toDouble();
                          });
                        },
                      ),

                      const SizedBox(height: 10),

                      // DISCOUNT AMOUNT
                      _summaryRow(
                        'Discount',
                        '-₱${discountAmount.toStringAsFixed(2)}',
                        valueColor: Colors.orangeAccent,
                      ),

                      const Divider(height: 24),

                      // FINAL TOTAL
                      _summaryRow(
                        'Total',
                        '₱${finalTotal.toStringAsFixed(2)}',
                        valueColor: AppTheme.emerald,
                        large: true,
                      ),

                      const SizedBox(height: 16),

                      // PAYMENT METHOD
                      DropdownButtonFormField<String>(
                        value: paymentMethod,
                        decoration: const InputDecoration(
                          labelText: 'Payment Method',
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'Cash',
                            child: Text('Cash'),
                          ),
                          DropdownMenuItem(
                            value: 'GCash',
                            child: Text('GCash'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              paymentMethod = value;
                            });
                          }
                        },
                      ),

                      const SizedBox(height: 12),

                      // COMPLETE SALE
                      FilledButton.icon(
                        onPressed:
                        cart.isEmpty || processing ? null : finishSale,
                        icon: const Icon(Icons.check_circle_outline),
                        label: Text(
                          processing ? 'Processing...' : 'Complete Sale',
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.emerald,
                          foregroundColor: AppTheme.navy,
                          padding: const EdgeInsets.all(15),
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

  Widget _summaryRow(
      String label,
      String value, {
        Color? valueColor,
        bool large = false,
      }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: large ? 20 : 15,
            fontWeight: large ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: large ? 25 : 15,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}