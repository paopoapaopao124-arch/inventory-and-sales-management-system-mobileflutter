
import 'package:flutter/material.dart';

import '../shared/app_theme.dart';
import '../admin/admin_dashboard.dart';
import '../staff/staff_dashboard.dart';
import '../customer/customer_dashboard.dart';

class RoleSelectionPage extends StatelessWidget {
  const RoleSelectionPage({super.key});

  void _openDashboard(BuildContext context, Widget page) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute<void>(
        builder: (_) => page,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.navy,
      appBar: AppBar(
        backgroundColor: AppTheme.navy,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text(
          'Select Your Role',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 12),
            const Center(
              child: Icon(
                Icons.shopping_cart_rounded,
                color: AppTheme.emerald,
                size: 58,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'StockSmart',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Choose how you want to access the system.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.muted,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 30),
            _roleCard(
              context,
              name: 'Admin',
              description:
              'Manage products, users, inventory, and reports.',
              icon: Icons.admin_panel_settings_rounded,
              color: AppTheme.emerald,
              page: const AdminDashboard(),
            ),
            const SizedBox(height: 16),
            _roleCard(
              context,
              name: 'Staff',
              description:
              'Scan products, process sales, and monitor stock.',
              icon: Icons.badge_rounded,
              color: const Color(0xFF3188F5),
              page: const StaffDashboard(),
            ),
            const SizedBox(height: 16),
            _roleCard(
              context,
              name: 'Customer',
              description:
              'Browse products, add to cart, and view orders.',
              icon: Icons.shopping_bag_rounded,
              color: const Color(0xFF9865F5),
              page: const CustomerDashboard(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _roleCard(
      BuildContext context, {
        required String name,
        required String description,
        required IconData icon,
        required Color color,
        required Widget page,
      }) {
    return Material(
      color: AppTheme.card,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _openDashboard(context, page),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: color.withValues(alpha: 0.65),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 32,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: const TextStyle(
                        color: AppTheme.muted,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: color,
                size: 28,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
