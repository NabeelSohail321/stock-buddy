import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stock_buddy/models/user_model.dart';
import 'package:stock_buddy/providers/user_provider.dart';
import 'package:stock_buddy/services/local_storage_service.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({Key? key}) : super(key: key);

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  bool _showInactive = true;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _initializeData();
  }

  Future<void> _loadCurrentUser() async {
    final user = await LocalStorageService().getUser();
    if (mounted) setState(() => _currentUser = user);
  }

  void _initializeData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<UserProvider>(context, listen: false).fetchUsers();
    });
  }

  bool get _isSuperAdmin => _currentUser?.role == 'super_admin';

  void _showCreateUserDialog() {
    showDialog(context: context, builder: (_) => CreateUserDialog(isSuperAdmin: _isSuperAdmin));
  }

  void _showEditUserDialog(Map<String, dynamic> user) {
    showDialog(context: context, builder: (_) => EditUserDialog(user: user, currentUser: _currentUser));
  }

  void _showResetPasswordDialog(Map<String, dynamic> user) {
    showDialog(context: context, builder: (_) => ResetPasswordDialog(user: user));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => Provider.of<UserProvider>(context, listen: false).fetchUsers(),
          ),
          if (_isSuperAdmin)
            IconButton(
              icon: const Icon(Icons.person_add),
              onPressed: _showCreateUserDialog,
              tooltip: 'Add New User',
            ),
        ],
      ),
      body: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          if (userProvider.isLoading && userProvider.users.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (userProvider.error.isNotEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${userProvider.error}',
                      style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
                  const SizedBox(height: 20),
                  ElevatedButton(onPressed: userProvider.fetchUsers, child: const Text('Retry')),
                ],
              ),
            );
          }

          final allUsers = userProvider.users;
          final displayUsers = _showInactive
              ? allUsers
              : allUsers.where((u) => u['isActive'] != false).toList();

          if (allUsers.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.people_outline, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('No users found', style: TextStyle(fontSize: 18, color: Colors.grey)),
                  if (_isSuperAdmin) ...[
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _showCreateUserDialog,
                      icon: const Icon(Icons.person_add),
                      label: const Text('Create First User'),
                    ),
                  ],
                ],
              ),
            );
          }

          return Column(
            children: [
              // Toggle inactive users visibility
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Text('${allUsers.where((u) => u['isActive'] == false).length} inactive user(s)',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                    const Spacer(),
                    const Text('Show inactive'),
                    Switch(
                      value: _showInactive,
                      activeColor: Colors.deepPurple,
                      onChanged: (v) => setState(() => _showInactive = v),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => userProvider.fetchUsers(),
                  child: ListView.builder(
                    itemCount: displayUsers.length,
                    itemBuilder: (context, index) {
                      final user = displayUsers[index];
                      return UserCard(
                        user: user,
                        currentUser: _currentUser,
                        isSuperAdmin: _isSuperAdmin,
                        onEdit: () => _showEditUserDialog(user),
                        onResetPassword: () => _showResetPasswordDialog(user),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: _isSuperAdmin
          ? FloatingActionButton(
              onPressed: _showCreateUserDialog,
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              child: const Icon(Icons.person_add),
            )
          : null,
    );
  }
}

class UserCard extends StatelessWidget {
  final Map<String, dynamic> user;
  final User? currentUser;
  final bool isSuperAdmin;
  final VoidCallback onEdit;
  final VoidCallback onResetPassword;

  const UserCard({
    Key? key,
    required this.user,
    required this.currentUser,
    required this.isSuperAdmin,
    required this.onEdit,
    required this.onResetPassword,
  }) : super(key: key);

  bool get _isTargetSuperAdmin => user['role'] == 'super_admin';
  bool get _isActive => user['isActive'] != false;

  @override
  Widget build(BuildContext context) {
    final email = user['email'] ?? 'No email';
    final name = user['name'] ?? 'Unknown User';
    final role = user['role'] ?? 'user';
    final lastLogin = user['lastLogin'];

    return Opacity(
      opacity: _isActive ? 1.0 : 0.6,
      child: Card(
        margin: const EdgeInsets.all(8.0),
        elevation: _isActive ? 2.0 : 1.0,
        color: _isActive ? null : Colors.grey.shade50,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text(email,
                            style: const TextStyle(color: Colors.grey, fontSize: 14)),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      _buildStatusBadge(_isActive),
                      const SizedBox(width: 8),
                      _buildRoleBadge(role),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildDetailRow('Role:', role.toUpperCase()),
              if (lastLogin != null)
                _buildDetailRow('Last Login:', _formatDate(lastLogin)),
              const SizedBox(height: 16),
              Row(
                children: [
                  // Reset password - available to super_admin for any user, and to admins for non-super_admin
                  if (isSuperAdmin || (!_isTargetSuperAdmin && (currentUser?.role == 'admin')))
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onResetPassword,
                        icon: const Icon(Icons.lock_reset, size: 16),
                        label: const Text('Reset Password'),
                        style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 8)),
                      ),
                    ),
                  if (isSuperAdmin || (!_isTargetSuperAdmin && (currentUser?.role == 'admin')))
                    const SizedBox(width: 8),
                  // Edit - super_admin can edit anyone; admin cannot edit super_admin
                  if (isSuperAdmin || !_isTargetSuperAdmin)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text('Edit User'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: isActive ? Colors.green.shade300 : Colors.red.shade300),
      ),
      child: Text(
        isActive ? 'Active' : 'Inactive',
        style: TextStyle(
          color: isActive ? Colors.green.shade700 : Colors.red.shade700,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildRoleBadge(String role) {
    Color color;
    switch (role) {
      case 'super_admin':
        color = Colors.red;
        break;
      case 'admin':
        color = Colors.purple;
        break;
      case 'staff':
        color = Colors.blue;
        break;
      case 'audits':
        color = Colors.orange;
        break;
      default:
        color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Text(
        role.toUpperCase().replaceAll('_', ' '),
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(label,
                style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.grey)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }
}

// Create User Dialog
class CreateUserDialog extends StatefulWidget {
  final bool isSuperAdmin;
  const CreateUserDialog({Key? key, required this.isSuperAdmin}) : super(key: key);

  @override
  State<CreateUserDialog> createState() => _CreateUserDialogState();
}

class _CreateUserDialogState extends State<CreateUserDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  String _selectedRole = 'staff';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _createUser() async {
    if (!_formKey.currentState!.validate()) return;
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final success = await userProvider.createUser(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      name: _nameController.text.trim(),
      role: _selectedRole,
    );
    if (success && context.mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User created successfully!'), backgroundColor: Colors.green));
    }
  }

  @override
  Widget build(BuildContext context) {
    final roleItems = <DropdownMenuItem<String>>[
      const DropdownMenuItem(value: 'staff', child: Text('Staff')),
      const DropdownMenuItem(value: 'admin', child: Text('Admin')),
      const DropdownMenuItem(value: 'audits', child: Text('Audits')),
      if (widget.isSuperAdmin)
        const DropdownMenuItem(value: 'super_admin', child: Text('Super Admin')),
    ];

    return AlertDialog(
      title: const Text('Create New User'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Full Name *', border: OutlineInputBorder()),
                validator: (v) => (v == null || v.isEmpty) ? 'Please enter full name' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email *', border: OutlineInputBorder()),
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Please enter email';
                  if (!v.contains('@')) return 'Please enter a valid email';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password *', border: OutlineInputBorder()),
                obscureText: true,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Please enter password';
                  if (v.length < 6) return 'Password must be at least 6 characters';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedRole,
                decoration: const InputDecoration(labelText: 'Role *', border: OutlineInputBorder()),
                items: roleItems,
                onChanged: (v) => setState(() => _selectedRole = v!),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(onPressed: _createUser, child: const Text('Create User')),
      ],
    );
  }
}

// Edit User Dialog
class EditUserDialog extends StatefulWidget {
  final Map<String, dynamic> user;
  final User? currentUser;

  const EditUserDialog({Key? key, required this.user, required this.currentUser}) : super(key: key);

  @override
  State<EditUserDialog> createState() => _EditUserDialogState();
}

class _EditUserDialogState extends State<EditUserDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String _selectedRole = 'staff';
  bool _isActive = true;

  bool get _isSuperAdmin => widget.currentUser?.role == 'super_admin';
  bool get _isTargetSuperAdmin => widget.user['role'] == 'super_admin';

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.user['name'] ?? '';
    _selectedRole = widget.user['role'] ?? 'staff';
    _isActive = widget.user['isActive'] != false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _updateUser() async {
    if (!_formKey.currentState!.validate()) return;
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final success = await userProvider.updateUser(
      userId: widget.user['_id'] ?? widget.user['id'],
      name: _nameController.text.trim(),
      role: _selectedRole,
      isActive: _isActive,
    );
    if (success && context.mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User updated successfully!'), backgroundColor: Colors.green));
    }
  }

  @override
  Widget build(BuildContext context) {
    final roleItems = <DropdownMenuItem<String>>[
      const DropdownMenuItem(value: 'staff', child: Text('Staff')),
      const DropdownMenuItem(value: 'admin', child: Text('Admin')),
      const DropdownMenuItem(value: 'audits', child: Text('Audits')),
      if (_isSuperAdmin)
        const DropdownMenuItem(value: 'super_admin', child: Text('Super Admin')),
    ];

    return AlertDialog(
      title: const Text('Edit User'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.user['email'] ?? 'No email',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Full Name *', border: OutlineInputBorder()),
                validator: (v) => (v == null || v.isEmpty) ? 'Please enter full name' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedRole,
                decoration: const InputDecoration(labelText: 'Role *', border: OutlineInputBorder()),
                items: roleItems,
                onChanged: (v) => setState(() => _selectedRole = v!),
              ),
              const SizedBox(height: 16),
              // Only super_admin can activate/deactivate; cannot deactivate another super_admin
              if (_isSuperAdmin && !_isTargetSuperAdmin)
                Row(
                  children: [
                    Checkbox(
                      value: _isActive,
                      onChanged: (v) => setState(() => _isActive = v!),
                    ),
                    const Text('Active User'),
                  ],
                )
              else if (_isTargetSuperAdmin)
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.shield, color: Colors.orange.shade700, size: 16),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text('Super Admin accounts cannot be deactivated.',
                            style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700, size: 16),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text('Only Super Admin can activate or deactivate users.',
                            style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(onPressed: _updateUser, child: const Text('Update User')),
      ],
    );
  }
}

// Reset Password Dialog
class ResetPasswordDialog extends StatefulWidget {
  final Map<String, dynamic> user;
  const ResetPasswordDialog({Key? key, required this.user}) : super(key: key);

  @override
  State<ResetPasswordDialog> createState() => _ResetPasswordDialogState();
}

class _ResetPasswordDialogState extends State<ResetPasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final success = await userProvider.resetUserPassword(
      userId: widget.user['_id'] ?? widget.user['id'],
      newPassword: _passwordController.text,
    );
    if (success && context.mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password reset successfully!'), backgroundColor: Colors.green));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Reset Password'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Reset password for ${widget.user['name']}',
                  style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'New Password *', border: OutlineInputBorder()),
                obscureText: true,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Please enter new password';
                  if (v.length < 6) return 'Password must be at least 6 characters';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmPasswordController,
                decoration: const InputDecoration(labelText: 'Confirm Password *', border: OutlineInputBorder()),
                obscureText: true,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Please confirm password';
                  if (v != _passwordController.text) return 'Passwords do not match';
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _resetPassword,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
          child: const Text('Reset Password'),
        ),
      ],
    );
  }
}
