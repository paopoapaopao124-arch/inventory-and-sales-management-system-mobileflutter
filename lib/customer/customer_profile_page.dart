import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../shared/app_theme.dart';

class CustomerProfilePage extends StatefulWidget {
  const CustomerProfilePage({super.key});

  @override
  State<CustomerProfilePage> createState() => _CustomerProfilePageState();
}

class _CustomerProfilePageState extends State<CustomerProfilePage> {
  late Future<Map<String, dynamic>> _profileFuture;

  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _barangayController = TextEditingController();
  final TextEditingController _streetNoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _profileFuture = ApiService.fetchCustomerProfile();
  }

  Future<void> _refreshProfile() async {
    setState(() {
      _profileFuture = ApiService.fetchCustomerProfile();
    });
    await _profileFuture;
  }

  void _showSnackBarMessage(String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    });
  }

  Future<void> _saveProfile() async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.maybeOf(context);
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final barangay = _barangayController.text.trim();
    final streetNo = _streetNoController.text.trim();

    if (name.isEmpty || phone.isEmpty || barangay.isEmpty || streetNo.isEmpty) {
      _showSnackBarMessage('Please complete all profile fields.');
      return;
    }

    try {
      await ApiService.updateCustomerProfile(
        name: name,
        phone: phone,
        barangay: barangay,
        streetNo: streetNo,
      );

      if (!mounted) return;

      navigator.pop();
      await _refreshProfile();
      messenger?.showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully.'),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      messenger?.showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  Future<void> _changePassword() async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.maybeOf(context);
    final currentPassword = _currentPasswordController.text.trim();
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (currentPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty) {
      _showSnackBarMessage('Please fill in all password fields.');
      return;
    }

    if (newPassword.length < 8) {
      _showSnackBarMessage('New password must be at least 8 characters long.');
      return;
    }

    if (newPassword != confirmPassword) {
      _showSnackBarMessage('New password and confirmation do not match.');
      return;
    }

    try {
      await ApiService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      );

      if (!mounted) return;

      if (navigator.mounted) {
        navigator.pop();
      }

      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      await _refreshProfile();

      if (!mounted) return;

      messenger?.showSnackBar(
        const SnackBar(
          content: Text('Password updated successfully.'),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      messenger?.showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  void _showProfileEditor() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final futureData = _profileFuture;

        return FutureBuilder<Map<String, dynamic>>(
          future: futureData,
          builder: (context, snapshot) {
            final profile = snapshot.data ?? <String, dynamic>{};
            _nameController.text = (profile['name'] ?? '').toString();
            _phoneController.text = (profile['phone'] ?? '').toString();
            _barangayController.text = (profile['barangay'] ?? '').toString();
            _streetNoController.text = (profile['street_no'] ?? '').toString();

            return AlertDialog(
              backgroundColor: AppTheme.card,
              title: const Text(
                'Edit Account Information',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _barangayController,
                      decoration: const InputDecoration(
                        labelText: 'Barangay',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _streetNoController,
                      decoration: const InputDecoration(
                        labelText: 'Street No./House No.',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: _saveProfile,
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showPasswordDialog() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppTheme.card,
          title: const Text(
            'Change Password',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _currentPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Current Password',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _newPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'New Password',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Confirm New Password',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: _changePassword,
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.navy,
      body: FutureBuilder<Map<String, dynamic>>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Unable to load your profile: ${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final user = snapshot.data ?? <String, dynamic>{};
          final fullAddress = (user['address'] as String?) ??
              '${user['street_no'] ?? 'N/A'}, ${user['barangay'] ?? 'N/A'}, ${user['municipality'] ?? 'Trinidad'}, Bohol';

          return ListView(
            padding: const EdgeInsets.all(18),
            children: [
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF103D4C),
                      Color(0xFF087B64),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.person,
                      size: 52,
                      color: AppTheme.emerald,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      user['name'] ?? 'Customer',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      user['email'] ?? 'No email available',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Card(
                color: AppTheme.card,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Account Information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _ProfileRow(label: 'Name', value: user['name'] ?? 'N/A'),
                      _ProfileRow(label: 'Email', value: user['email'] ?? 'N/A'),
                      _ProfileRow(label: 'Phone Number', value: user['phone'] ?? 'N/A'),
                      _ProfileRow(label: 'Municipality', value: user['municipality'] ?? 'Trinidad'),
                      _ProfileRow(label: 'Barangay', value: user['barangay'] ?? 'N/A'),
                      _ProfileRow(label: 'Street No.', value: user['street_no'] ?? 'N/A'),
                      _ProfileRow(label: 'Address', value: fullAddress),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _showProfileEditor,
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit Account Information'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _showPasswordDialog,
                  icon: const Icon(Icons.lock_reset),
                  label: const Text('Change Password'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _barangayController.dispose();
    _streetNoController.dispose();
    super.dispose();
  }
}

class _ProfileRow extends StatelessWidget {
  final String label;
  final String value;

  const _ProfileRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                color: AppTheme.muted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
