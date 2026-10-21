import 'dart:convert';

import 'package:flutter/material.dart';

import '../auth/login_page.dart';
import '../data/store_data.dart';
import '../models/product.dart';
import '../models/sale_transaction.dart';
import '../shared/app_theme.dart';
import '../staff/barcode_scanner_page.dart';
import 'product_form_page.dart';
import 'products_page.dart';
import 'top_selling_products_page.dart';
import 'user_management_page.dart';
import '../shared/sales_summary_card.dart';
import '../shared/low_stock_alert.dart';
import '../shared/void_transaction_dialog.dart';
import '../screens/profile_settings_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;
  final StoreData store = StoreData.instance;

  String _selectedPeriod = 'Weekly';

  final List<String> _titles = const [
    'Admin Dashboard',
    'Manage Products',
    'Stock Overview',
    'User Management',
    'Sales Report',
    'Profile & Settings',
  ];

  String _money(double amount) => '₱${amount.toStringAsFixed(2)}';

  @override
  void initState() {
    super.initState();
    store.load();
  }

  List<SaleTransaction> get _filteredSales {
    final now = DateTime.now();

    final startOfWeek = DateTime(
      now.year,
      now.month,
      now.day - now.weekday + 1,
    );

    return store.transactions.where((sale) {
      if (sale.isVoided) return false;

      final date = sale.date;

      switch (_selectedPeriod) {
        case 'Weekly':
          return !date.isBefore(startOfWeek) &&
              date.isBefore(
                DateTime(now.year, now.month, now.day + 1),
              );

        case 'Monthly':
          return date.year == now.year && date.month == now.month;

        case 'Yearly':
          return date.year == now.year;

        default:
          return false;
      }
    }).toList();
  }

  double get _periodSalesTotal {
    return _filteredSales.fold(
      0.0,
          (total, sale) => total + sale.total,
    );
  }

  // NEW: today's non-voided transactions (for Sales Summary)
  List<SaleTransaction> get _todayTransactions {
    final now = DateTime.now();
    return store.transactions
        .where((s) =>
    !s.isVoided &&
        s.date.year == now.year &&
        s.date.month == now.month &&
        s.date.day == now.day)
        .toList();
  }

  // NEW: low-stock list (for banner and bell)
  List<LowStockItem> get _lowStockItems => store.products
      .where((p) => p.isLowStock || p.isOutOfStock)
      .map((p) => LowStockItem(name: p.name, quantity: p.stock))
      .toList();

  // OPEN THE ADD PRODUCT FORM (same form used for Edit)
  Future<void> _openAddProduct() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => const ProductFormPage(),
      ),
    );

    if (!mounted) return;

    if (result == true) {
      setState(() => _selectedIndex = 1);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Product added successfully!'),
          backgroundColor: AppTheme.emerald,
        ),
      );
    }
  }

  // SCAN BARCODE AND FIND PRODUCT
  Future<void> _scanBarcode() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => const BarcodeScannerPage(),
      ),
    );

    if (!mounted || result == null) return;

    final barcode = result.trim();

    final matches = store.products.where(
          (product) => product.barcode.trim() == barcode,
    );

    if (matches.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No product found for barcode: $barcode'),
          action: SnackBarAction(
            label: 'Add Product',
            onPressed: () {
              setState(() => _selectedIndex = 1);
              _showAddProductDialog(initialBarcode: barcode);
            },
          ),
        ),
      );
      return;
    }

    final product = matches.first;

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.card,
        title: const Text(
          'Product Found',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              product.emoji,
              style: const TextStyle(fontSize: 42),
            ),
            const SizedBox(height: 12),
            _detail('Product Name', product.name),
            _detail('Barcode', product.barcode),
            _detail('Price', _money(product.price)),
            _detail('Available Stock', '${product.stock} units'),
            _detail(
              'Status',
              product.isOutOfStock
                  ? 'Out of Stock'
                  : product.isLowStock
                  ? 'Low Stock'
                  : 'In Stock',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(
              'Close',
              style: TextStyle(color: AppTheme.emerald),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              setState(() => _selectedIndex = 1);
            },
            child: const Text('View Products'),
          ),
        ],
      ),
    );
  }

  Widget _detail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: AppTheme.muted),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.navy,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: store,
          builder: (context, _) {
            return Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: IndexedStack(
                    index: _selectedIndex,
                    children: [
                      _buildHome(),
                      // Product Records table (search, edit, delete, add)
                      const ProductsPage(embedded: true),
                      _buildStock(),
                      const UserManagementPage(),
                      _buildSalesReport(),
                      _buildProfile(),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.emerald.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.storefront_rounded,
              color: AppTheme.emerald,
              size: 27,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _titles[_selectedIndex],
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // NEW: low stock bell
          LowStockBell(items: _lowStockItems),
          IconButton(
            tooltip: 'Profile',
            onPressed: () => setState(() => _selectedIndex = 5),
            icon: const Icon(
              Icons.account_circle_rounded,
              color: AppTheme.emerald,
              size: 29,
            ),
          ),
          IconButton(
            tooltip: 'Logout',
            onPressed: _confirmLogout,
            icon: const Icon(
              Icons.logout_rounded,
              color: AppTheme.danger,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHome() {
    final recentSales = store.transactions.take(5).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF00C98D), Color(0xFF087B68)],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total Sales',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _money(store.totalSales),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${store.transactionCount} completed transactions',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.show_chart_rounded,
                color: Colors.white,
                size: 48,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _statCard(
                'Total Products',
                '${store.productCount}',
                Icons.inventory_2_rounded,
                Colors.lightBlueAccent,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _statCard(
                'Low Stock Items',
                '${store.lowStockCount}',
                Icons.warning_amber_rounded,
                Colors.orangeAccent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _statCard(
                'Stock Units',
                '${store.totalUnits}',
                Icons.warehouse_rounded,
                AppTheme.emerald,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _statCard(
                'Out of Stock',
                '${store.products.where((p) => p.isOutOfStock).length}',
                Icons.remove_shopping_cart,
                AppTheme.danger,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _sectionTitle('Product View'),
        const SizedBox(height: 12),
        if (store.products.isEmpty)
          _emptyState(
            Icons.inventory_2_rounded,
            'No Products Yet',
            'Products you save will appear in this table.',
          )
        else
          ProductRecordsTable(products: store.products),
        const SizedBox(height: 24),
        _sectionTitle('Quick Actions'),
        const SizedBox(height: 12),
        _actionTile(
          icon: Icons.add_box_rounded,
          title: 'Add New Product',
          subtitle: 'Register a product in your inventory',
          color: AppTheme.emerald,
          onTap: _openAddProduct,
        ),
        const SizedBox(height: 10),
        _actionTile(
          icon: Icons.qr_code_scanner_rounded,
          title: 'Scan Barcode',
          subtitle: 'Scan and find a registered product',
          color: AppTheme.emerald,
          onTap: _scanBarcode,
        ),
        const SizedBox(height: 10),
        _actionTile(
          icon: Icons.warehouse_rounded,
          title: 'Stock Overview',
          subtitle: 'Check available and low-stock items',
          color: Colors.lightBlueAccent,
          onTap: () => setState(() => _selectedIndex = 2),
        ),
        const SizedBox(height: 10),
        _actionTile(
          icon: Icons.people_alt_rounded,
          title: 'User Management',
          subtitle: 'Manage staff and customer accounts',
          color: Colors.lightBlueAccent,
          onTap: () => setState(() => _selectedIndex = 3),
        ),
        const SizedBox(height: 10),
        _actionTile(
          icon: Icons.receipt_long_rounded,
          title: 'Sales Transactions',
          subtitle: 'View completed sales',
          color: Colors.purpleAccent,
          onTap: () => setState(() => _selectedIndex = 4),
        ),
        const SizedBox(height: 10),
        _actionTile(
          icon: Icons.bar_chart_rounded,
          title: 'Sales Reports',
          subtitle: 'View sales and inventory summaries',
          color: Colors.orangeAccent,
          onTap: () => setState(() => _selectedIndex = 4),
        ),
        const SizedBox(height: 18),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _sectionTitle('Recent Sales'),
            TextButton(
              onPressed: () => setState(() => _selectedIndex = 4),
              child: const Text(
                'View All',
                style: TextStyle(color: AppTheme.emerald),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (recentSales.isEmpty)
          _emptyState(
            Icons.receipt_long_rounded,
            'No sales yet',
            'Completed sales will appear here.',
          )
        else
        // CHANGED: uses _saleRow so each sale has a Void button
          ...recentSales.map((sale) => _saleRow(sale)),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _sectionTitle('Low Stock Alerts'),
            TextButton(
              onPressed: () => setState(() => _selectedIndex = 2),
              child: const Text(
                'View All',
                style: TextStyle(color: AppTheme.emerald),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        _buildLowStockPreview(),
        _actionTile(
          icon: Icons.trending_up_rounded,
          title: 'Top Selling Products',
          subtitle: 'View best-selling products',
          color: AppTheme.emerald,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const TopSellingProductsPage(),
              ),
            );
          },
        ),
      ],
    );
  }
  Widget _todayStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
  Widget _statCard(
      String title,
      String value,
      IconData icon,
      Color color,
      ) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 25),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 23,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              color: AppTheme.muted,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStock() {
    final products = store.products;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
      children: [
        _sectionTitle('Stock Overview'),
        const SizedBox(height: 8),
        const Text(
          'Monitor your available inventory.',
          style: TextStyle(color: AppTheme.muted),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _statCard(
                'In Stock',
                '${products.where((p) => !p.isLowStock && !p.isOutOfStock).length}',
                Icons.check_circle_outline,
                AppTheme.emerald,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _statCard(
                'Low Stock',
                '${products.where((p) => p.isLowStock).length}',
                Icons.warning_amber_rounded,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _statCard(
                'Out',
                '${products.where((p) => p.isOutOfStock).length}',
                Icons.remove_shopping_cart,
                AppTheme.danger,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        if (products.isEmpty)
          _emptyState(
            Icons.warehouse_rounded,
            'No stock available',
            'Add products to see inventory here.',
          ),
        ...products.map((product) => _productCard(product)),
      ],
    );
  }

  Widget _buildSalesReport() {
    final products = store.products;
    final allTransactions = store.transactions;
    final now = DateTime.now();

    final startOfWeek = DateTime(
      now.year,
      now.month,
      now.day - now.weekday + 1,
    );

    final startOfToday = DateTime(
      now.year,
      now.month,
      now.day,
    );

    final endOfToday = startOfToday.add(
      const Duration(days: 1),
    );

    final filteredTransactions = allTransactions.where((sale) {
      if (sale.isVoided) return false;

      final date = sale.date;

      switch (_selectedPeriod) {
        case 'Weekly':
          return !date.isBefore(startOfWeek) && date.isBefore(endOfToday);

        case 'Monthly':
          return date.year == now.year &&
              date.month == now.month &&
              date.isBefore(endOfToday);

        case 'Yearly':
          return date.year == now.year && date.isBefore(endOfToday);

        default:
          return false;
      }
    }).toList();

    final periodSalesTotal = filteredTransactions.fold<double>(
      0.0,
          (total, sale) => total + sale.total,
    );

    final outOfStockCount = products.where((p) => p.isOutOfStock).length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
      children: [
        _sectionTitle('Sales Report'),
        const SizedBox(height: 8),
        const Text(
          'Sales transactions and inventory summary',
          style: TextStyle(color: AppTheme.muted),
        ),
        const SizedBox(height: 20),
        const Text(
          'Select Sales Period',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: ['Weekly', 'Monthly', 'Yearly'].map((period) {
            final selected = _selectedPeriod == period;

            return Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ChoiceChip(
                  label: Text(period),
                  selected: selected,
                  showCheckmark: false,
                  selectedColor: AppTheme.emerald,
                  backgroundColor: AppTheme.card,
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : AppTheme.muted,
                    fontWeight: FontWeight.w600,
                  ),
                  onSelected: (value) {
                    if (!value) return;

                    setState(() {
                      _selectedPeriod = period;
                    });
                  },
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        _statCard(
          '$_selectedPeriod Sales',
          _money(periodSalesTotal),
          Icons.payments_rounded,
          AppTheme.emerald,
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _statCard(
                'Transactions',
                '${filteredTransactions.length}',
                Icons.receipt_long_rounded,
                Colors.purpleAccent,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _statCard(
                "Today's Sales",
                _money(store.todaySales),
                Icons.trending_up_rounded,
                Colors.lightBlueAccent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _sectionTitle('$_selectedPeriod Sales History'),
        const SizedBox(height: 12),
        if (filteredTransactions.isEmpty)
          _emptyState(
            Icons.receipt_long_rounded,
            'No sales for $_selectedPeriod',
            'Completed checkout transactions for this period will appear here.',
          )
        else
        // CHANGED: uses _saleRow so each sale has a Void button
          ...filteredTransactions.map((sale) => _saleRow(sale)),
        const SizedBox(height: 24),
        _sectionTitle('Inventory Summary'),
        const SizedBox(height: 12),
        _reportRow('Total Products', '${store.productCount}'),
        _reportRow('Total Stock Units', '${store.totalUnits}'),
        _reportRow('Low Stock Items', '${store.lowStockCount}'),
        _reportRow('Out of Stock Items', '$outOfStockCount'),
        const SizedBox(height: 20),
        _sectionTitle('Product Stock Status'),
        const SizedBox(height: 10),
        if (products.isEmpty)
          _emptyState(
            Icons.inventory_2_rounded,
            'No products',
            'Add products to see their stock status.',
          )
        else
          ...products.map((product) {
            final status = product.isOutOfStock
                ? 'Out of Stock'
                : product.isLowStock
                ? 'Low Stock'
                : 'In Stock';

            return _reportRow(
              product.name,
              '$status • ${product.stock} units',
            );
          }),
      ],
    );
  }

  Widget _buildProfile() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 90),
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppTheme.emerald.withValues(alpha: 0.25),
            ),
          ),
          child: const Column(
            children: [
              CircleAvatar(
                radius: 42,
                backgroundColor: AppTheme.emerald,
                child: Icon(
                  Icons.person_rounded,
                  size: 48,
                  color: AppTheme.navy,
                ),
              ),
              SizedBox(height: 14),
              Text(
                'Administrator',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 5),
              Text(
                'StockSmart Inventory Management',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.muted),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _sectionTitle('Account & Settings'),
        const SizedBox(height: 12),
        // CHANGED: opens the Manage Profile screen
        _actionTile(
          icon: Icons.person_outline,
          title: 'Profile Information',
          subtitle: 'Update account information and settings',
          color: Colors.lightBlueAccent,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProfileSettingsScreen(
                name: 'Administrator',
                email: 'admin@stocksmart.com', // TODO: use the real email
                role: 'Admin',
                onSaveProfile: (name, phone) async {}, // TODO: connect backend
                onChangePassword: (current, next) async {}, // TODO
                onLowStockAlertsChanged: (enabled) {}, // TODO
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        _actionTile(
          icon: Icons.store_outlined,
          title: 'Business Information',
          subtitle: 'Inventory and sales management',
          color: AppTheme.emerald,
          onTap: () => _showInfo(
            'Business Information',
            'StockSmart\nInventory and Sales Management System',
          ),
        ),
        const SizedBox(height: 10),
        _actionTile(
          icon: Icons.notifications_active_outlined,
          title: 'Low Stock Notifications',
          subtitle: '${store.lowStockCount} low-stock products',
          color: Colors.orangeAccent,
          onTap: () => setState(() => _selectedIndex = 2),
        ),
        const SizedBox(height: 10),
        _actionTile(
          icon: Icons.bar_chart_rounded,
          title: 'Reports & Analytics',
          subtitle: 'View inventory and sales summaries',
          color: Colors.purpleAccent,
          onTap: () => setState(() => _selectedIndex = 4),
        ),
        const SizedBox(height: 18),
        ElevatedButton.icon(
          onPressed: _confirmLogout,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.danger.withValues(alpha: 0.15),
            foregroundColor: AppTheme.danger,
            padding: const EdgeInsets.all(16),
          ),
          icon: const Icon(Icons.logout_rounded),
          label: const Text('Log Out'),
        ),
      ],
    );
  }

  Future<void> _editProduct(Product product) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ProductFormPage(product: product),
      ),
    );

    if (!mounted) return;

    if (result == true) {
      setState(() {});
    }
  }

  // Product card used in the Stock Overview tab
  Widget _productCard(Product product) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // PRODUCT IMAGE
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _buildProductImage(product),
                ),
                const SizedBox(width: 14),

                // Product information
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF101B35),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Brand: ${product.brand.isNotEmpty ? product.brand : "No brand"}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Category: ${product.category}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '₱${product.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                const Icon(
                  Icons.inventory_2_outlined,
                  size: 18,
                  color: Colors.grey,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Stock: ${product.stock}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (product.isLowStock)
                  const Text(
                    'LOW STOCK',
                    style: TextStyle(
                      color: Colors.deepOrange,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _editProduct(product),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Update'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLowStockPreview() {
    final lowStock =
    store.products.where((p) => p.isLowStock || p.isOutOfStock).toList();

    if (lowStock.isEmpty) {
      return _emptyState(
        Icons.check_circle_outline,
        'Inventory looks good',
        'There are no low-stock products right now.',
      );
    }

    return Column(
      children: lowStock.take(5).map((product) {
        return _reportRow(
          product.name,
          product.isOutOfStock ? 'OUT OF STOCK' : '${product.stock} left',
          valueColor: product.isOutOfStock ? AppTheme.danger : Colors.orange,
        );
      }).toList(),
    );
  }

  Widget _actionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppTheme.card,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppTheme.muted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppTheme.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 17,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _emptyState(
      IconData icon,
      String title,
      String message,
      ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppTheme.muted, size: 42),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.muted),
          ),
        ],
      ),
    );
  }

  // CHANGED: added optional `action` (used for the Void button)
  Widget _reportRow(
      String title,
      String value, {
        String? subtitle,
        Color valueColor = Colors.white,
        Widget? action,
      }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.white),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppTheme.muted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                color: valueColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (action != null) action,
        ],
      ),
    );
  }

  // NEW: sale row with a Void button
  Widget _saleRow(SaleTransaction sale) {
    return _reportRow(
      sale.id,
      sale.isVoided ? 'VOIDED' : _money(sale.total),
      subtitle: '${_formatDate(sale.date)} • ${sale.paymentMethod}',
      valueColor: sale.isVoided ? AppTheme.danger : AppTheme.emerald,
      action: sale.isVoided
          ? null
          : IconButton(
        tooltip: 'Void',
        onPressed: () => _voidSale(sale),
        icon: const Icon(
          Icons.cancel_outlined,
          color: AppTheme.danger,
          size: 20,
        ),
      ),
    );
  }
  Future<void> _voidSale(SaleTransaction sale) async {
    final voided = await showVoidTransactionDialog(
      context,
      saleId: sale.id,
      total: sale.total,
      isAdmin: true,
      onVoid: (reason) => store.voidTransaction(sale.id),
    );

    if (!mounted || !voided) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Transaction voided.')),
    );
  }
  Widget _buildBottomNavigation() {
    const labels = [
      'Home',
      'Products',
      'Stock',
      'Users',
      'Sales Report',
      'Profile',
    ];

    const icons = [
      Icons.dashboard_rounded,
      Icons.inventory_2_rounded,
      Icons.warehouse_rounded,
      Icons.people_alt_rounded,
      Icons.bar_chart_rounded,
      Icons.person_rounded,
    ];

    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      type: BottomNavigationBarType.fixed,
      backgroundColor: AppTheme.card,
      selectedItemColor: AppTheme.emerald,
      unselectedItemColor: AppTheme.muted,
      selectedFontSize: 10,
      unselectedFontSize: 9,
      onTap: (index) {
        setState(() => _selectedIndex = index);
      },
      items: List.generate(
        labels.length,
            (index) => BottomNavigationBarItem(
          icon: Icon(icons[index]),
          label: labels[index],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  // Quick-add dialog (used when a scanned barcode is not registered yet)
  Future<void> _showAddProductDialog({
    String initialBarcode = '',
  }) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final brandController = TextEditingController();
    final priceController = TextEditingController();
    final stockController = TextEditingController();
    final barcodeController = TextEditingController(text: initialBarcode);
    final emojiController = TextEditingController(text: '📦');
    final descriptionController = TextEditingController();
    final categoryController = TextEditingController();

    bool isSaving = false;
    String? saveError;

    try {
      final saved = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (dialogContext, setDialogState) {
              return AlertDialog(
                backgroundColor: AppTheme.card,
                title: const Text(
                  'Add Product',
                  style: TextStyle(color: Colors.white),
                ),
                content: SizedBox(
                  width: 400,
                  child: SingleChildScrollView(
                    child: Form(
                      key: formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _formField(
                            nameController,
                            'Product Name',
                            'Enter name',
                          ),
                          _formField(
                            priceController,
                            'Price (₱)',
                            '0.00',
                            decimal: true,
                          ),
                          _formField(
                            stockController,
                            'Stock Quantity',
                            '0',
                            wholeNumber: true,
                          ),
                          _formField(
                            barcodeController,
                            'Barcode (optional)',
                            'Enter barcode',
                            requiredField: false,
                          ),
                          _formField(
                            emojiController,
                            'Product Emoji',
                            '📦',
                            requiredField: false,
                          ),
                          _formField(
                            brandController,
                            'Brand',
                            'Enter brand name',
                          ),
                          TextFormField(
                            controller: descriptionController,
                            maxLines: 2,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              labelText: 'Product Description',
                              hintText: 'Enter product details',
                              prefixIcon: Icon(Icons.description_outlined),
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: categoryController,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              labelText: 'Category',
                              hintText:
                              'e.g. Beverages, Snacks, Canned Goods',
                              prefixIcon: Icon(Icons.category_outlined),
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Enter a product category';
                              }
                              return null;
                            },
                          ),
                          if (saveError != null) ...[
                            const SizedBox(height: 12),
                            Text(
                              saveError!,
                              style: const TextStyle(
                                color: AppTheme.danger,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: isSaving
                        ? null
                        : () => Navigator.pop(dialogContext, false),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: isSaving
                        ? null
                        : () async {
                      if (!formKey.currentState!.validate()) {
                        return;
                      }

                      final price = double.tryParse(
                        priceController.text.trim(),
                      );
                      final quantity = int.tryParse(
                        stockController.text.trim(),
                      );
                      final barcode = barcodeController.text.trim();

                      if (price == null ||
                          quantity == null ||
                          price < 0 ||
                          quantity < 0) {
                        setDialogState(() {
                          saveError =
                          'Enter a valid price and quantity.';
                        });
                        return;
                      }

                      final duplicateBarcode = barcode.isNotEmpty &&
                          store.products.any(
                                (p) => p.barcode.trim() == barcode,
                          );

                      if (duplicateBarcode) {
                        setDialogState(() {
                          saveError =
                          'This barcode is already registered.';
                        });
                        return;
                      }

                      setDialogState(() {
                        isSaving = true;
                        saveError = null;
                      });

                      final product = Product(
                        id: DateTime.now()
                            .microsecondsSinceEpoch
                            .toString(),
                        name: nameController.text.trim(),
                        price: price,
                        stock: quantity,
                        barcode: barcode,
                        emoji: emojiController.text.trim().isEmpty
                            ? '📦'
                            : emojiController.text.trim(),
                        description:
                        descriptionController.text.trim(),
                        category: categoryController.text.trim(),
                        brand: brandController.text.trim(),
                        imageUrl: '',
                      );

                      try {
                        await store.addProduct(product);

                        if (!mounted || !dialogContext.mounted) {
                          return;
                        }

                        Navigator.pop(dialogContext, true);
                      } catch (error) {
                        if (!dialogContext.mounted) return;

                        setDialogState(() {
                          isSaving = false;
                          saveError =
                          'Unable to save product. Please try again.';
                        });
                      }
                    },
                    child: isSaving
                        ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                        : const Text('Save Product'),
                  ),
                ],
              );
            },
          );
        },
      );

      if (saved == true && mounted) {
        setState(() => _selectedIndex = 1);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product saved successfully.'),
          ),
        );
      }
    } finally {
      nameController.dispose();
      priceController.dispose();
      stockController.dispose();
      barcodeController.dispose();
      emojiController.dispose();
      descriptionController.dispose();
      categoryController.dispose();
      brandController.dispose();
    }
  }

  Widget _formField(
      TextEditingController controller,
      String label,
      String hint, {
        bool decimal = false,
        bool wholeNumber = false,
        bool requiredField = true,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: decimal || wholeNumber
            ? TextInputType.numberWithOptions(decimal: decimal)
            : TextInputType.text,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: const TextStyle(color: AppTheme.muted),
          filled: true,
          fillColor: AppTheme.field,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        validator: (value) {
          final text = value?.trim() ?? '';

          if (requiredField && text.isEmpty) {
            return 'This field is required';
          }

          if (text.isEmpty) return null;

          if (decimal) {
            final number = double.tryParse(text);
            if (number == null || number < 0) {
              return 'Enter a valid price';
            }
          }

          if (wholeNumber) {
            final number = int.tryParse(text);
            if (number == null || number < 0) {
              return 'Enter a valid quantity';
            }
          }

          return null;
        },
      ),
    );
  }

  void _showInfo(String title, String message) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.card,
        title: Text(
          title,
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          message,
          style: const TextStyle(color: AppTheme.muted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(
              'Close',
              style: TextStyle(color: AppTheme.emerald),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.card,
        title: const Text(
          'Log out?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to log out?',
          style: TextStyle(color: AppTheme.muted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              'Log Out',
              style: TextStyle(color: AppTheme.danger),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => const LoginPage(),
      ),
          (route) => false,
    );
  }

  // Shows the uploaded picture, or the product emoji if there is none.
  Widget _buildProductImage(Product product) {
    final imageData = product.imageUrl;

    if (imageData.startsWith('data:image/') && imageData.contains(',')) {
      try {
        final bytes = base64Decode(imageData.split(',').last);

        return Image.memory(
          bytes,
          width: 58,
          height: 58,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(
              Icons.broken_image_outlined,
              size: 30,
              color: Colors.grey,
            );
          },
        );
      } catch (_) {
        return const Icon(
          Icons.broken_image_outlined,
          size: 30,
          color: Colors.grey,
        );
      }
    }

    return Center(
      child: Text(
        product.emoji,
        style: const TextStyle(fontSize: 28),
      ),
    );
  }
}