import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/product.dart';
import '../models/sale_transaction.dart';

class StoreData extends ChangeNotifier {
  StoreData._();

  static final StoreData instance = StoreData._();

  static const String _storageKey = 'stocks_mart_products_v1';
  static const String _salesStorageKey = 'stocks_mart_sales_v1';

  final List<Product> products = [];
  final List<SaleTransaction> transactions = [];

  bool _loaded = false;

  bool get isLoaded => _loaded;

  int get productCount => products.length;

  int get totalUnits =>
      products.fold(0, (sum, product) => sum + product.stock);

  int get lowStockCount =>
      products.where((product) => product.isLowStock).length;

  // Exclude voided transactions from sales totals.
  double get totalSales => transactions
      .where((sale) => !sale.isVoided)
      .fold(0.0, (sum, sale) => sum + sale.total);

  int get transactionCount =>
      transactions.where((sale) => !sale.isVoided).length;

  double get todaySales {
    final now = DateTime.now();

    return transactions
        .where(
          (sale) =>
      !sale.isVoided &&
          sale.date.year == now.year &&
          sale.date.month == now.month &&
          sale.date.day == now.day,
    )
        .fold(0.0, (sum, sale) => sum + sale.total);
  }

  List<Product> _defaultPhones() => [
    Product(
      id: 'P101',
      name: 'RealMe Note 80',
      price: 8000,
      stock: 21,
      barcode: '200001',
      emoji: '📱',
      brand: 'Realme',
      category: 'smartphones',
      description:
      'Affordable smartphone with stylish design, smooth performance, clear display, capable camera, and long-lasting battery for everyday use.',
    ),
    Product(
      id: 'P102',
      name: 'iPhone 15',
      price: 39999,
      stock: 5,
      barcode: '200002',
      emoji: '📱',
      brand: 'Apple',
      category: 'smartphones',
      description:
      'Stylish 5G smartphone with smooth performance, high-quality cameras, bright display, and dependable battery life.',
    ),
  ];

  Future<void> load() async {
    if (_loaded) return;

    final prefs = await SharedPreferences.getInstance();

    // Load products.
    final savedProducts = prefs.getString(_storageKey);

    if (savedProducts != null) {
      final decoded = jsonDecode(savedProducts) as List<dynamic>;

      products
        ..clear()
        ..addAll(
          decoded.map(
                (item) => Product.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          ),
        );
    } else {
      // Default products for a brand-new installation.
      products.addAll(_defaultPhones());

      await _saveProductsWithoutNotification();
    }

    // One-time cleanup: remove ONLY the untouched old sample products
    // (matched by name, so edited products are never deleted).
    const cleanupKey = 'stocks_mart_sample_cleanup_v2';

    if (prefs.getBool(cleanupKey) != true) {
      const oldSampleNames = {'bottled water', 'chips', 'bread', 'milk'};
      final before = products.length;

      products.removeWhere(
            (product) =>
            oldSampleNames.contains(product.name.trim().toLowerCase()),
      );

      if (products.length != before) {
        await _saveProductsWithoutNotification();
      }

      await prefs.setBool(cleanupKey, true);
    }

    // If there are no products at all, start with the smartphone products.
    if (products.isEmpty) {
      products.addAll(_defaultPhones());
      await _saveProductsWithoutNotification();
    }

    // Load saved sales transactions.
    final savedSales = prefs.getString(_salesStorageKey);

    if (savedSales != null) {
      final decodedSales = jsonDecode(savedSales) as List<dynamic>;

      transactions
        ..clear()
        ..addAll(
          decodedSales.map(
                (item) => SaleTransaction.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          ),
        );
    }

    _loaded = true;
    notifyListeners();
  }

  // Save products without notifying listeners.
  Future<void> _saveProductsWithoutNotification() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      _storageKey,
      jsonEncode(
        products.map((product) => product.toJson()).toList(),
      ),
    );
  }

  // Save products and notify listeners.
  Future<void> _saveAndNotify() async {
    await _saveProductsWithoutNotification();
    notifyListeners();
  }

  // Save sales transactions.
  Future<void> _saveSalesWithoutNotification() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      _salesStorageKey,
      jsonEncode(
        transactions.map((sale) => sale.toJson()).toList(),
      ),
    );
  }

  // Add a new product.
  Future<void> addProduct(Product product) async {
    if (products.any((item) => item.id == product.id)) {
      throw StateError('A product with this ID already exists.');
    }

    products.add(product);

    try {
      await _saveAndNotify();
    } catch (_) {
      products.removeWhere((item) => item.id == product.id);
      rethrow;
    }
  }

  // Update an existing product.
  Future<void> updateProduct(Product updated) async {
    final index = products.indexWhere((p) => p.id == updated.id);

    if (index == -1) {
      throw StateError('Product not found.');
    }

    final oldProduct = products[index];
    products[index] = updated;

    try {
      await _saveAndNotify();
    } catch (_) {
      products[index] = oldProduct;
      rethrow;
    }
  }

  // Delete a product.
  Future<void> deleteProduct(String id) async {
    final index = products.indexWhere((p) => p.id == id);

    if (index == -1) {
      throw StateError('Product not found.');
    }

    final removedProduct = products.removeAt(index);

    try {
      await _saveAndNotify();
    } catch (_) {
      products.insert(index, removedProduct);
      rethrow;
    }
  }

  // Find a product using its barcode.
  Product? findByBarcode(String barcode) {
    for (final product in products) {
      if (product.barcode.trim() == barcode.trim()) {
        return product;
      }
    }

    return null;
  }

  // Reduce stock for a product.
  Future<void> reduceStock(Product product, int quantity) async {
    if (quantity <= 0) {
      throw ArgumentError('Quantity must be greater than zero.');
    }

    final index = products.indexWhere((p) => p.id == product.id);

    if (index == -1) {
      throw StateError('Product not found.');
    }

    final existing = products[index];

    if (existing.stock < quantity) {
      throw StateError('Not enough stock available.');
    }

    final oldStock = existing.stock;
    existing.stock -= quantity;

    try {
      await _saveAndNotify();
    } catch (_) {
      existing.stock = oldStock;
      rethrow;
    }
  }

  // Complete a sale with discount support.
  Future<SaleTransaction> completeSale({
    required Map<String, int> quantities,
    required String paymentMethod,
    double discountAmount = 0.0,
    String discountType = 'None',
  }) async {
    if (quantities.isEmpty) {
      throw StateError('Your cart is empty.');
    }

    // Validate every product before changing stock.
    for (final entry in quantities.entries) {
      final index = products.indexWhere((p) => p.id == entry.key);

      if (index == -1) {
        throw StateError('A product in your cart no longer exists.');
      }

      if (entry.value <= 0) {
        throw StateError('Invalid product quantity.');
      }

      if (products[index].stock < entry.value) {
        throw StateError(
          'Not enough stock for ${products[index].name}.',
        );
      }
    }

    // Create sale items using current product prices.
    final items = <SaleItem>[];

    for (final entry in quantities.entries) {
      final product = products.firstWhere(
            (p) => p.id == entry.key,
      );

      items.add(
        SaleItem(
          productId: product.id,
          productName: product.name,
          quantity: entry.value,
          unitPrice: product.price,
        ),
      );
    }

    // Calculate subtotal before discount.
    final subtotal = items.fold<double>(
      0.0,
          (sum, item) => sum + item.subtotal,
    );

    // Prevent negative discounts or discounts above subtotal.
    if (!discountAmount.isFinite) {
      throw ArgumentError('Invalid discount amount.');
    }

    final safeDiscount = discountAmount.clamp(0.0, subtotal);
    final total = subtotal - safeDiscount;

    final transaction = SaleTransaction(
      id: 'S${DateTime.now().microsecondsSinceEpoch}',
      date: DateTime.now(),
      items: items,
      total: total,
      paymentMethod: paymentMethod,
      discountAmount: safeDiscount,
      discountType: discountType,
    );

    // Remember original stock in case saving fails.
    final originalStock = <String, int>{
      for (final entry in quantities.entries)
        entry.key: products.firstWhere(
              (p) => p.id == entry.key,
        ).stock,
    };

    // Reduce stock.
    for (final entry in quantities.entries) {
      final product = products.firstWhere(
            (p) => p.id == entry.key,
      );

      product.stock -= entry.value;
    }

    // Add the new transaction.
    transactions.insert(0, transaction);

    try {
      await _saveProductsWithoutNotification();
      await _saveSalesWithoutNotification();
    } catch (_) {
      // Restore stock if saving fails.
      for (final entry in originalStock.entries) {
        final product = products.firstWhere(
              (p) => p.id == entry.key,
        );

        product.stock = entry.value;
      }

      transactions.removeWhere((sale) => sale.id == transaction.id);
      rethrow;
    }

    notifyListeners();
    return transaction;
  }

  // Void a transaction and restore sold stock.
  Future<void> voidTransaction(String transactionId, {String? reason}) async {
    final transactionIndex = transactions.indexWhere(
          (sale) => sale.id == transactionId,
    );

    if (transactionIndex == -1) {
      throw StateError('Transaction not found.');
    }

    final transaction = transactions[transactionIndex];

    if (transaction.isVoided) {
      throw StateError('This transaction has already been voided.');
    }

    // Validate products before restoring stock.
    for (final item in transaction.items) {
      final exists = products.any(
            (product) => product.id == item.productId,
      );

      if (!exists) {
        throw StateError(
          'Cannot void this sale because product '
              '"${item.productName}" no longer exists in inventory.',
        );
      }
    }

    // Remember original stock in case saving fails.
    final originalStock = <String, int>{
      for (final item in transaction.items)
        item.productId: products.firstWhere(
              (p) => p.id == item.productId,
        ).stock,
    };
    final updatedTransaction = transaction.copyWith(
      isVoided: true,
      voidedAt: DateTime.now(),
      voidReason: reason,
    );

    // Restore stock for all sold items.
    for (final item in transaction.items) {
      final product = products.firstWhere(
            (p) => p.id == item.productId,
      );

      product.stock += item.quantity;
    }

    transactions[transactionIndex] = updatedTransaction;

    try {
      await _saveProductsWithoutNotification();
      await _saveSalesWithoutNotification();
    } catch (_) {
      // Roll back changes if saving fails.
      for (final entry in originalStock.entries) {
        final product = products.firstWhere(
              (p) => p.id == entry.key,
        );

        product.stock = entry.value;
      }

      transactions[transactionIndex] = transaction;
      rethrow;
    }

    notifyListeners();
  }
}