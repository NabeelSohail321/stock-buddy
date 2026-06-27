import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stock_buddy/models/manager_model.dart';
import 'package:stock_buddy/models/location_model.dart';
import 'package:stock_buddy/providers/manager_provider.dart';
import 'package:stock_buddy/providers/location_provider.dart';

class AddEditManagerScreen extends StatefulWidget {
  final Manager? manager;

  const AddEditManagerScreen({super.key, this.manager});

  @override
  State<AddEditManagerScreen> createState() => _AddEditManagerScreenState();
}

class _AddEditManagerScreenState extends State<AddEditManagerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  List<String> _selectedLocationIds = [];
  bool _isActive = true;

  bool _notifStock = true;
  bool _notifRepair = true;
  bool _notifDisposal = true;
  bool _notifTransfer = true;

  bool get _isEditing => widget.manager != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _nameController.text = widget.manager!.name;
      _emailController.text = widget.manager!.email;
      _phoneController.text = widget.manager!.phone ?? '';
      _selectedLocationIds = List.from(widget.manager!.assignedLocationIds);
      _isActive = widget.manager!.isActive;
      _notifStock = widget.manager!.notificationPreferences.stock;
      _notifRepair = widget.manager!.notificationPreferences.repair;
      _notifDisposal = widget.manager!.notificationPreferences.disposal;
      _notifTransfer = widget.manager!.notificationPreferences.transfer;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LocationProvider>().loadLocations();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<ManagerProvider>();
    final prefs = {
      'stock': _notifStock,
      'repair': _notifRepair,
      'disposal': _notifDisposal,
      'transfer': _notifTransfer,
    };

    bool success;
    if (_isEditing) {
      success = await provider.updateManager(
        managerId: widget.manager!.id,
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        assignedLocationIds: _selectedLocationIds,
        notificationPreferences: prefs,
        isActive: _isActive,
      );
    } else {
      success = await provider.createManager(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        assignedLocationIds: _selectedLocationIds,
        notificationPreferences: prefs,
      );
    }

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_isEditing ? 'Manager updated successfully!' : 'Manager created successfully!'),
        backgroundColor: Colors.green,
      ));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Manager' : 'Add Manager'),
        backgroundColor: Colors.teal.shade700,
        foregroundColor: Colors.white,
      ),
      body: Consumer2<ManagerProvider, LocationProvider>(
        builder: (context, managerProvider, locationProvider, _) {
          if (managerProvider.error.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(managerProvider.error),
                backgroundColor: Colors.red,
              ));
              managerProvider.clearError();
            });
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSection('Manager Details', [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name *',
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => (v == null || v.isEmpty) ? 'Please enter name' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email *',
                        prefixIcon: Icon(Icons.email_outlined),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Please enter email';
                        if (!v.contains('@')) return 'Please enter a valid email';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Phone (Optional)',
                        prefixIcon: Icon(Icons.phone_outlined),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    if (_isEditing) ...[
                      const SizedBox(height: 16),
                      Row(children: [
                        const Text('Active', style: TextStyle(fontSize: 16)),
                        const Spacer(),
                        Switch(
                          value: _isActive,
                          activeColor: Colors.teal,
                          onChanged: (v) => setState(() => _isActive = v),
                        ),
                      ]),
                    ],
                  ]),
                  const SizedBox(height: 20),

                  _buildSection('Assign Locations', [
                    if (locationProvider.isLoading)
                      const Center(child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(),
                      ))
                    else if (locationProvider.locations.isEmpty)
                      const Text('No locations available. Create locations first.',
                          style: TextStyle(color: Colors.grey))
                    else
                      _buildLocationSelector(locationProvider.locations),
                  ]),
                  const SizedBox(height: 20),

                  _buildSection('Email Notification Preferences', [
                    const Text(
                      'Choose which events this manager receives email notifications for:',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    _buildNotifToggle('Stock events (add stock, transfers)', _notifStock,
                        Icons.inventory_2_outlined, (v) => setState(() => _notifStock = v)),
                    _buildNotifToggle('Repair events', _notifRepair,
                        Icons.build_outlined, (v) => setState(() => _notifRepair = v)),
                    _buildNotifToggle('Disposal events', _notifDisposal,
                        Icons.delete_outline, (v) => setState(() => _notifDisposal = v)),
                    _buildNotifToggle('Transfer events', _notifTransfer,
                        Icons.compare_arrows, (v) => setState(() => _notifTransfer = v)),
                  ]),
                  const SizedBox(height: 28),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: managerProvider.isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal.shade700,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: managerProvider.isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : Text(
                              _isEditing ? 'Update Manager' : 'Create Manager',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildLocationSelector(List<Location> locations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: locations.map((loc) {
        final selected = _selectedLocationIds.contains(loc.id);
        return CheckboxListTile(
          value: selected,
          title: Text(loc.name),
          activeColor: Colors.teal,
          contentPadding: EdgeInsets.zero,
          dense: true,
          onChanged: (val) {
            setState(() {
              if (val == true) {
                _selectedLocationIds.add(loc.id);
              } else {
                _selectedLocationIds.remove(loc.id);
              }
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildNotifToggle(String label, bool value, IconData icon, ValueChanged<bool> onChanged) {
    return Row(
      children: [
        Icon(icon, size: 20, color: value ? Colors.teal : Colors.grey.shade400),
        const SizedBox(width: 10),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 14))),
        Switch(value: value, activeColor: Colors.teal, onChanged: onChanged),
      ],
    );
  }
}
