import 'package:flutter/material.dart';

/// Manage Profile & Settings screen.
/// Backend-agnostic: you pass the current values and save callbacks.
class ProfileSettingsScreen extends StatefulWidget {
  final String name;
  final String email;
  final String role; // e.g. "Admin" or "Staff"
  final String? phone;
  final bool lowStockAlerts;

  final Future<void> Function(String name, String phone) onSaveProfile;
  final Future<void> Function(String currentPassword, String newPassword)
  onChangePassword;
  final void Function(bool enabled) onLowStockAlertsChanged;

  const ProfileSettingsScreen({
    super.key,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
    this.lowStockAlerts = true,
    required this.onSaveProfile,
    required this.onChangePassword,
    required this.onLowStockAlertsChanged,
  });

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  late final TextEditingController _name;
  late final TextEditingController _phone;
  final _currentPw = TextEditingController();
  final _newPw = TextEditingController();
  final _confirmPw = TextEditingController();
  late bool _lowStockAlerts;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.name);
    _phone = TextEditingController(text: widget.phone ?? '');
    _lowStockAlerts = widget.lowStockAlerts;
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _currentPw.dispose();
    _newPw.dispose();
    _confirmPw.dispose();
    super.dispose();
  }

  void _msg(String text, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(text),
      backgroundColor: error ? Colors.redAccent : Colors.teal,
    ));
  }

  Future<void> _saveProfile() async {
    if (_name.text.trim().isEmpty) {
      _msg('Name cannot be empty.', error: true);
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.onSaveProfile(_name.text.trim(), _phone.text.trim());
      _msg('Profile updated.');
    } catch (e) {
      _msg('Could not save profile: $e', error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _changePassword() async {
    if (_currentPw.text.isEmpty || _newPw.text.isEmpty) {
      _msg('Fill in the password fields.', error: true);
      return;
    }
    if (_newPw.text.length < 6) {
      _msg('New password must be at least 6 characters.', error: true);
      return;
    }
    if (_newPw.text != _confirmPw.text) {
      _msg('New passwords do not match.', error: true);
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.onChangePassword(_currentPw.text, _newPw.text);
      _currentPw.clear();
      _newPw.clear();
      _confirmPw.clear();
      _msg('Password changed.');
    } catch (e) {
      _msg('Could not change password: $e', error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1A2B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B1A2B),
        foregroundColor: Colors.white,
        title: const Text('Profile & Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 40,
                  backgroundColor: Color(0xFF1E8E6E),
                  child: Icon(Icons.person, size: 44, color: Colors.white),
                ),
                const SizedBox(height: 10),
                Text(widget.role,
                    style: const TextStyle(
                        color: Colors.tealAccent,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _section('Account Information'),
          _field(_name, 'Full name'),
          const SizedBox(height: 12),
          _field(TextEditingController(text: widget.email), 'Email',
              readOnly: true),
          const SizedBox(height: 12),
          _field(_phone, 'Phone number', keyboard: TextInputType.phone),
          const SizedBox(height: 16),
          _button('Save Profile', _saveProfile),
          const SizedBox(height: 28),
          _section('Change Password'),
          _field(_currentPw, 'Current password', obscure: true),
          const SizedBox(height: 12),
          _field(_newPw, 'New password', obscure: true),
          const SizedBox(height: 12),
          _field(_confirmPw, 'Confirm new password', obscure: true),
          const SizedBox(height: 16),
          _button('Update Password', _changePassword),
          const SizedBox(height: 28),
          _section('Preferences'),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            activeColor: Colors.tealAccent,
            title: const Text('Low stock notifications',
                style: TextStyle(color: Colors.white)),
            subtitle: const Text('Alert me when products reach minimum stock',
                style: TextStyle(color: Colors.white60)),
            value: _lowStockAlerts,
            onChanged: (v) {
              setState(() => _lowStockAlerts = v);
              widget.onLowStockAlertsChanged(v);
            },
          ),
        ],
      ),
    );
  }

  Widget _section(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(title,
        style: const TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.bold)),
  );

  Widget _field(
      TextEditingController c,
      String label, {
        bool obscure = false,
        bool readOnly = false,
        TextInputType? keyboard,
      }) {
    return TextField(
      controller: c,
      obscureText: obscure,
      readOnly: readOnly,
      keyboardType: keyboard,
      style: TextStyle(color: readOnly ? Colors.white54 : Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white60),
        filled: true,
        fillColor: const Color(0xFF12283D),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.tealAccent),
        ),
      ),
    );
  }

  Widget _button(String label, VoidCallback onTap) => SizedBox(
    width: double.infinity,
    height: 48,
    child: FilledButton(
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFF1E8E6E),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: _saving ? null : onTap,
      child: _saving
          ? const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2))
          : Text(label),
    ),
  );
}