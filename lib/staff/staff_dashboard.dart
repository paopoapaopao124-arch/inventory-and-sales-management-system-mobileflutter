import 'package:flutter/material.dart';

import '../admin/stock_overview_page.dart';
import '../auth/login_page.dart';
import '../data/store_data.dart';
import '../shared/app_theme.dart';
import '../shared/widgets.dart';
import 'barcode_scanner_page.dart';
import 'checkout_page.dart';
import 'transaction_history_page.dart';

class StaffDashboard extends StatelessWidget {
  const StaffDashboard({super.key});

  void _logout(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
          (_) => false,
    );
  }

  Future<void> _action(BuildContext context, String title) async {
    if (title == 'Checkout / Sell') {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const CheckoutPage(),
        ),
      );
    } else if (title == 'Stock Overview') {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const StockOverviewPage(),
        ),
      );
    } else if (title == 'Transactions') {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const TransactionHistoryPage(),
        ),
      );
    } else if (title == 'Scan Barcode') {
      await _scanProduct(context);
    }
  }

  // Scan a barcode, look the product up, and show its details.
  Future<void> _scanProduct(BuildContext context) async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => const BarcodeScannerPage(),
      ),
    );

    if (!context.mounted || result == null) return;

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

    final status = product.isOutOfStock
        ? 'Out of Stock'
        : product.isLowStock
        ? 'Low Stock'
        : 'In Stock';

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.card,
        title: const Text('Product Found'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                product.emoji,
                style: const TextStyle(fontSize: 42),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              product.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text('Barcode: ${product.barcode}'),
            Text('Price: ₱${product.price.toStringAsFixed(2)}'),
            Text('Stock: ${product.stock} units'),
            Text('Status: $status'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: product.isOutOfStock
                ? null
                : () {
              Navigator.pop(dialogContext);
              _action(context, 'Checkout / Sell');
            },
            icon: const Icon(Icons.point_of_sale),
            label: const Text('Go to Checkout'),
          ),
        ],
      ),
    );
  }

  void _showMore(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppTheme.card,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'More Options',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.point_of_sale),
                title: const Text('Checkout / Sell'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _action(context, 'Checkout / Sell');
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Logout'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _logout(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Staff Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: StoreData.instance,
        builder: (context, _) {
          final store = StoreData.instance;
          final now = DateTime.now();

          final todayTransactions = store.transactions.where((sale) {
            return !sale.isVoided &&
                sale.date.year == now.year &&
                sale.date.month == now.month &&
                sale.date.day == now.day;
          }).length;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Welcome banner
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF087B64),
                      AppTheme.emerald,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.storefront,
                      size: 36,
                      color: Colors.white,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Welcome, Staff!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Manage checkout, sales, and store inventory.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Today's sales
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: AppTheme.card,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: AppTheme.emerald.withValues(alpha: 0.6),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.payments_outlined,
                          color: AppTheme.emerald,
                        ),
                        SizedBox(width: 8),
                        Text(
                          "Today's Sales",
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '₱ ${store.todaySales.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.emerald,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$todayTransactions completed transactions today',
                      style: const TextStyle(
                        color: AppTheme.muted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              const Text(
                'Store Overview',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.25,
                children: [
                  DashboardCard(
                    label: 'Total Products',
                    value: '${store.productCount}',
                    icon: Icons.inventory_2_outlined,
                  ),
                  DashboardCard(
                    label: 'Low Stock Items',
                    value: '${store.lowStockCount}',
                    icon: Icons.warning_amber,
                    iconColor: AppTheme.danger,
                  ),
                  DashboardCard(
                    label: 'Transactions',
                    value: '${store.transactionCount}',
                    icon: Icons.receipt_long,
                  ),
                  DashboardCard(
                    label: 'Units in Stock',
                    value: '${store.totalUnits}',
                    icon: Icons.warehouse_outlined,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              const Text(
                'Daily Operations',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              _operationTile(
                context,
                title: 'Scan Barcode',
                subtitle: 'Find products by barcode',
                icon: Icons.qr_code_scanner,
              ),
              _operationTile(
                context,
                title: 'Checkout / Sell',
                subtitle: 'Create a sale and update stock',
                icon: Icons.point_of_sale,
              ),
              _operationTile(
                context,
                title: 'Stock Overview',
                subtitle: 'View available and low-stock items',
                icon: Icons.warehouse_outlined,
              ),
              _operationTile(
                context,
                title: 'Transactions',
                subtitle: 'View sales, voided transactions, and receipts',
                icon: Icons.receipt_long,
              ),

              const SizedBox(height: 20),
            ],
          );
        },
      ),

      // Horizontal navigation at the bottom
      bottomNavigationBar: NavigationBar(
        backgroundColor: AppTheme.card,
        indicatorColor: AppTheme.emerald.withValues(alpha: 0.18),
        selectedIndex: 0,
        onDestinationSelected: (index) {
          switch (index) {
            case 0:
            // Already on Home.
              break;
            case 1:
              _action(context, 'Scan Barcode');
              break;
            case 2:
              _action(context, 'Stock Overview');
              break;
            case 3:
              _action(context, 'Transactions');
              break;
            case 4:
              _showMore(context);
              break;
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.qr_code_scanner),
            label: 'Scan',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            label: 'Stock',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            label: 'Transaction',
          ),
          NavigationDestination(
            icon: Icon(Icons.more_horiz),
            label: 'More',
          ),
        ],
      ),
    );
  }

  Widget _operationTile(
      BuildContext context, {
        required String title,
        required String subtitle,
        required IconData icon,
      }) {
    return Card(
      color: AppTheme.card,
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 6,
        ),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.emerald.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppTheme.emerald),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _action(context, title),
      ),
    );
  }
}