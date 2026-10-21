
import 'package:flutter/material.dart';

import '../auth/login_page.dart';
import '../models/product.dart';
import '../services/api_service.dart';
import '../shared/app_theme.dart';
import 'customer_checkout_page.dart';
import 'customer_orders_page.dart';
import 'customer_profile_page.dart';
import 'product_details_page.dart';

class CustomerDashboard extends StatefulWidget {
  const CustomerDashboard({super.key});

  @override
  State<CustomerDashboard> createState() => _CustomerDashboardState();
}

class _CustomerDashboardState extends State<CustomerDashboard> {
  final TextEditingController searchController = TextEditingController();
  final Map<String, int> cart = {};
  List<Product> _products = [];
  bool _loadingProducts = false;
  int selectedIndex = 0;
  String _ordersTabKey = 'orders-initial';

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => _loadingProducts = true);

    try {
      final products = await ApiService.fetchProducts();
      if (!mounted) return;
      setState(() => _products = products);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to load products from the server.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _loadingProducts = false);
      }
    }
  }

  List<Product> get filteredProducts {
    final query = searchController.text.trim().toLowerCase();

    return _products.where((product) {
      return product.name.toLowerCase().contains(query);
    }).toList();
  }

  double get cartTotal {
    double total = 0;

    for (final entry in cart.entries) {
      final matches = _products.where((product) => product.id == entry.key);
      if (matches.isNotEmpty) {
        total += matches.first.price * entry.value;
      }
    }

    return total;
  }

  int get cartCount =>
      cart.values.fold(0, (sum, quantity) => sum + quantity);

  void _onTabSelected(int index) {
    setState(() {
      selectedIndex = index;
      if (index == 2) {
        _ordersTabKey = 'orders-${DateTime.now().millisecondsSinceEpoch}';
      }
    });
  }

  int addToCart(Product product) {
    if (product.stock <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This product is out of stock.'),
        ),
      );
      return cartCount;
    }

    final currentQuantity = cart[product.id] ?? 0;
    if (currentQuantity >= product.stock) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You have reached the available stock.'),
        ),
      );
      return cartCount;
    }

    setState(() {
      cart[product.id] = currentQuantity + 1;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product.name} added to cart.'),
        duration: const Duration(milliseconds: 900),
      ),
    );

    return cartCount;
  }

  void removeFromCart(Product product) {
    setState(() {
      final quantity = cart[product.id] ?? 0;
      if (quantity <= 1) {
        cart.remove(product.id);
      } else {
        cart[product.id] = quantity - 1;
      }
    });
  }

  void _showLogoutDialog() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppTheme.card,
          title: const Text(
            'Logout',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'Are you sure you want to log out?',
            style: TextStyle(color: AppTheme.muted),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute<void>(
                    builder: (_) => const LoginPage(),
                  ),
                  (route) => false,
                );
              },
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.emerald,
                foregroundColor: AppTheme.navy,
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final products = filteredProducts;

    return Scaffold(
      backgroundColor: AppTheme.navy,
      appBar: AppBar(
        backgroundColor: AppTheme.navy,
        title: const Row(
          children: [
            Icon(Icons.shopping_bag, color: AppTheme.emerald),
            SizedBox(width: 10),
            Text(
              'StockSmart',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Center(
              child: Badge(
                label: Text('$cartCount'),
                isLabelVisible: cartCount > 0,
                child: IconButton(
                  tooltip: 'My Cart',
                  icon: const Icon(
                    Icons.shopping_cart_outlined,
                    color: AppTheme.emerald,
                  ),
                  onPressed: () => setState(() => selectedIndex = 1),
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout, color: AppTheme.danger),
            onPressed: _showLogoutDialog,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: IndexedStack(
        index: selectedIndex,
        children: [
          _buildHome(products),
          _buildCart(),
          CustomerOrdersPage(key: ValueKey(_ordersTabKey)),
          _buildProfilePage(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: const Color(0xFF0C2940),
        indicatorColor: AppTheme.emerald.withValues(alpha: 0.18),
        selectedIndex: selectedIndex,
        onDestinationSelected: _onTabSelected,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.shopping_cart_outlined),
            selectedIcon: Icon(Icons.shopping_cart),
            label: 'My Cart',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'My Orders',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildHome(List<Product> products) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(
              colors: [
                Color(0xFF103D4C),
                Color(0xFF087B64),
              ],
            ),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SMART INVENTORY',
                style: TextStyle(
                  color: AppTheme.emerald,
                  letterSpacing: 2,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Welcome to StockSmart!',
                style: TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Browse available products and shop with ease.',
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        TextField(
          controller: searchController,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: 'Search products...',
            prefixIcon: const Icon(Icons.search),
            filled: true,
            fillColor: AppTheme.card,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 22),
        const Text(
          'Featured Products',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        if (_loadingProducts)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (products.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: Text('No products found.')),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: products.length,
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 230,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              mainAxisExtent: 230,
            ),
            itemBuilder: (context, index) {
              final product = products[index];
              final quantity = cart[product.id] ?? 0;

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProductDetailsPage(
                        product: product,
                        initialCartCount: cartCount,
                        onAddToCart: () => addToCart(product),
                        onOpenCart: () => setState(() => selectedIndex = 1),
                      ),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.card,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: AppTheme.emerald.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: product.imageUrl.isNotEmpty
                              ? Image.network(
                                  product.imageUrl,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Center(
                                      child: Text(
                                        product.emoji,
                                        style: const TextStyle(fontSize: 48),
                                      ),
                                    );
                                  },
                                )
                              : Center(
                                  child: Text(
                                    product.emoji,
                                    style: const TextStyle(fontSize: 48),
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        product.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '₱${product.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: AppTheme.emerald,
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: product.stock <= quantity
                              ? null
                              : () => addToCart(product),
                          child: Text(
                            product.stock == 0
                                ? 'Out of Stock'
                                : quantity > 0
                                    ? 'Added ($quantity)'
                                    : 'Add to Cart',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildCart() {
    final cartEntries = cart.entries.toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'My Cart',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        if (cartEntries.isEmpty)
          const Padding(
            padding: EdgeInsets.all(35),
            child: Column(
              children: [
                Icon(
                  Icons.shopping_cart_outlined,
                  size: 60,
                  color: AppTheme.muted,
                ),
                SizedBox(height: 12),
                Text('Your cart is empty.'),
                Text(
                  'Add products from the Home screen.',
                  style: TextStyle(color: AppTheme.muted),
                ),
              ],
            ),
          )
        else
          ...cartEntries.map((entry) {
            final matches = _products.where((product) => product.id == entry.key);
            if (matches.isEmpty) {
              return const SizedBox.shrink();
            }

            final product = matches.first;
            final quantity = entry.value;

            return Card(
              color: AppTheme.card,
              child: ListTile(
                leading: Text(
                  product.emoji,
                  style: const TextStyle(fontSize: 28),
                ),
                title: Text(product.name),
                subtitle: Text(
                  '₱${product.price.toStringAsFixed(2)} × $quantity',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () => removeFromCart(product),
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                    Text('$quantity'),
                    IconButton(
                      onPressed: quantity >= product.stock
                          ? null
                          : () => addToCart(product),
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                  ],
                ),
              ),
            );
          }),
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
              const Text('Order Total'),
              const SizedBox(height: 8),
              Text(
                '₱${cartTotal.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: AppTheme.emerald,
                  fontSize: 27,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: cart.isEmpty
                      ? null
                      : () async {
                          final orderQuantities = Map<String, int>.from(cart);

                          final completed = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute<bool>(
                              builder: (_) => CustomerCheckoutPage(
                                quantities: orderQuantities,
                                products: List<Product>.from(_products),
                              ),
                            ),
                          );

                          if (!mounted) return;

                          if (completed == true) {
                            setState(() {
                              cart.clear();
                              selectedIndex = 2;
                              _ordersTabKey = 'orders-${DateTime.now().millisecondsSinceEpoch}';
                            });
                          }
                        },
                  icon: const Icon(Icons.shopping_bag_outlined),
                  label: const Text('Proceed to Checkout'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfilePage() {
    return const CustomerProfilePage();
  }
}

