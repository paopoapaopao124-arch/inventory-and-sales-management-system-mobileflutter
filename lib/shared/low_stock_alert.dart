import 'package:flutter/material.dart';

/// Products with quantity at or below this number are "low stock".
const int kLowStockThreshold = 10;

class LowStockItem {
  final String name;
  final int quantity;
  const LowStockItem({required this.name, required this.quantity});
}

/// Finds low-stock products from ANY list of your own product objects.
///
/// final lowStock = findLowStock(
///   products,
///   name: (p) => p.name,
///   quantity: (p) => p.quantity,
/// );
List<LowStockItem> findLowStock<T>(
    Iterable<T> products, {
      required String Function(T) name,
      required int Function(T) quantity,
      int threshold = kLowStockThreshold,
    }) {
  final items = products
      .where((p) => quantity(p) <= threshold)
      .map((p) => LowStockItem(name: name(p), quantity: quantity(p)))
      .toList();
  items.sort((a, b) => a.quantity.compareTo(b.quantity));
  return items;
}

/// Bottom sheet listing all low-stock items.
void showLowStockSheet(BuildContext context, List<LowStockItem> items) {
  showModalBottomSheet(
    context: context,
    backgroundColor: const Color(0xFF0F2438),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Low Stock Items',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (items.isEmpty)
              const Text('All products are well stocked.',
                  style: TextStyle(color: Colors.white70))
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: items.length,
                  separatorBuilder: (_, __) =>
                  const Divider(color: Colors.white12),
                  itemBuilder: (_, i) {
                    final item = items[i];
                    final out = item.quantity == 0;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        Icons.warning_amber_rounded,
                        color: out ? Colors.redAccent : Colors.amber,
                      ),
                      title: Text(item.name,
                          style: const TextStyle(color: Colors.white)),
                      trailing: Text(
                        out ? 'Out of stock' : '${item.quantity} left',
                        style: TextStyle(
                          color: out ? Colors.redAccent : Colors.amber,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

/// Yellow banner for the top of the dashboard. Hidden when nothing is low.
class LowStockBanner extends StatelessWidget {
  final List<LowStockItem> items;
  const LowStockBanner({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return GestureDetector(
      onTap: () => showLowStockSheet(context, items),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0x33FFC107),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0x80FFC107)),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.amber),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '${items.length} product${items.length == 1 ? '' : 's'} '
                    'running low on stock',
                style: const TextStyle(
                    color: Colors.amber, fontWeight: FontWeight.w600),
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.amber),
          ],
        ),
      ),
    );
  }
}

/// Bell icon with a count badge. Put it in the header next to the profile icon.
class LowStockBell extends StatelessWidget {
  final List<LowStockItem> items;
  const LowStockBell({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () => showLowStockSheet(context, items),
      icon: Badge(
        isLabelVisible: items.isNotEmpty,
        label: Text('${items.length}'),
        child: const Icon(Icons.notifications_rounded, color: Colors.white),
      ),
    );
  }
}

/// Optional: pop up a SnackBar once when the dashboard opens.
void notifyLowStock(BuildContext context, List<LowStockItem> items) {
  if (items.isEmpty) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      backgroundColor: const Color(0xFFB8860B),
      content: Text(
          'Low stock: ${items.first.name}'
              '${items.length > 1 ? ' and ${items.length - 1} more' : ''}'),
      action: SnackBarAction(
        label: 'VIEW',
        textColor: Colors.white,
        onPressed: () => showLowStockSheet(context, items),
      ),
    ),
  );
}