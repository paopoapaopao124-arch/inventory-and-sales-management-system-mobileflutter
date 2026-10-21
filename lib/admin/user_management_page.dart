
import 'package:flutter/material.dart';

import '../data/user_data.dart';
import '../models/app_user.dart';
import '../shared/app_theme.dart';

class UserManagementPage extends StatelessWidget {
  const UserManagementPage({super.key});

  Future<void> _openForm(
      BuildContext context, {
        AppUser? user,
      }) async {
    await showDialog<void>(
      context: context,
      builder: (_) => _UserFormDialog(user: user),
    );
  }

  Future<void> _deleteUser(
      BuildContext context,
      AppUser user,
      ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Delete the record for ${user.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      await UserData.instance.deleteUser(user.id);

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User deleted successfully.')),
      );
    } catch (error) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context),
        backgroundColor: AppTheme.emerald,
        foregroundColor: AppTheme.navy,
        icon: const Icon(Icons.person_add),
        label: const Text('Add User'),
      ),
      body: AnimatedBuilder(
        animation: UserData.instance,
        builder: (context, _) {
          final data = UserData.instance;
          final users = data.users;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            children: [
              const Text(
                'Manage Accounts',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Add and maintain user records and assigned roles.',
                style: TextStyle(color: AppTheme.muted),
              ),
              const SizedBox(height: 18),

              Row(
                children: [
                  Expanded(
                    child: _CountCard(
                      title: 'Admins',
                      count: data.adminCount,
                      icon: Icons.admin_panel_settings,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _CountCard(
                      title: 'Staff',
                      count: data.staffCount,
                      icon: Icons.badge,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _CountCard(
                      title: 'Customers',
                      count: data.customerCount,
                      icon: Icons.people,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Registered Users',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Total: ${data.totalUsers}',
                    style: TextStyle(color: AppTheme.muted),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              if (users.isEmpty)
                Card(
                  color: AppTheme.card,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 48,
                          color: AppTheme.muted,
                        ),
                        const SizedBox(height: 12),
                        const Text('No users added yet.'),
                        const SizedBox(height: 6),
                        Text(
                          'Tap Add User to create your first record.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppTheme.muted),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...users.map(
                      (user) => Card(
                    color: AppTheme.card,
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                        AppTheme.emerald.withValues(alpha: 0.15),
                        child: Icon(
                          user.role == 'Admin'
                              ? Icons.admin_panel_settings
                              : user.role == 'Staff'
                              ? Icons.badge
                              : Icons.person,
                          color: AppTheme.emerald,
                        ),
                      ),
                      title: Text(
                        user.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        '@${user.username}\n'
                            '${user.role} • '
                            '${user.isActive ? 'Active' : 'Inactive'}',
                      ),
                      isThreeLine: true,
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'edit') {
                            _openForm(context, user: user);
                          } else if (value == 'delete') {
                            _deleteUser(context, user);
                          }
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(
                            value: 'edit',
                            child: Text('Edit'),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Text('Delete'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 12),
              Text(
                'These are local user records. Login credentials and '
                    'server-side permissions are not configured by this page.',
                style: TextStyle(
                  color: AppTheme.muted,
                  fontSize: 12,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CountCard extends StatelessWidget {
  final String title;
  final int count;
  final IconData icon;

  const _CountCard({
    required this.title,
    required this.count,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppTheme.card,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: 6,
        ),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.emerald, size: 25),
            const SizedBox(height: 8),
            Text(
              '$count',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.muted,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserFormDialog extends StatefulWidget {
  final AppUser? user;

  const _UserFormDialog({this.user});

  @override
  State<_UserFormDialog> createState() => _UserFormDialogState();
}

class _UserFormDialogState extends State<_UserFormDialog> {
  late final TextEditingController nameController;
  late final TextEditingController usernameController;

  String role = 'Staff';
  bool isActive = true;
  bool saving = false;

  @override
  void initState() {
    super.initState();

    final user = widget.user;

    nameController = TextEditingController(
      text: user?.name ?? '',
    );

    usernameController = TextEditingController(
      text: user?.username ?? '',
    );

    if (user != null) {
      role = user.role;
      isActive = user.isActive;
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    usernameController.dispose();
    super.dispose();
  }

  Future<void> saveUser() async {
    if (saving) return;

    setState(() => saving = true);

    try {
      if (widget.user == null) {
        await UserData.instance.addUser(
          name: nameController.text,
          username: usernameController.text,
          role: role,
        );
      } else {
        await UserData.instance.updateUser(
          id: widget.user!.id,
          name: nameController.text,
          username: usernameController.text,
          role: role,
          isActive: isActive,
        );
      }

      if (!mounted) return;

      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.user == null ? 'Add User' : 'Edit User',
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: usernameController,
              decoration: const InputDecoration(
                labelText: 'Username',
                prefixIcon: Icon(Icons.alternate_email),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: role,
              decoration: const InputDecoration(
                labelText: 'Role',
                prefixIcon: Icon(Icons.security),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'Admin',
                  child: Text('Admin'),
                ),
                DropdownMenuItem(
                  value: 'Staff',
                  child: Text('Staff'),
                ),
                DropdownMenuItem(
                  value: 'Customer',
                  child: Text('Customer'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => role = value);
                }
              },
            ),
            if (widget.user != null) ...[
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Active'),
                value: isActive,
                onChanged: (value) {
                  setState(() => isActive = value);
                },
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: saving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: saving ? null : saveUser,
          child: Text(saving ? 'Saving...' : 'Save User'),
        ),
      ],
    );
  }
}
