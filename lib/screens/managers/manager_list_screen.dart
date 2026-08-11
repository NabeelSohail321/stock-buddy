import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stock_buddy/models/manager_model.dart';
import 'package:stock_buddy/providers/manager_provider.dart';
import 'add_edit_manager_screen.dart';

class ManagerListScreen extends StatefulWidget {
  const ManagerListScreen({super.key});

  @override
  State<ManagerListScreen> createState() => _ManagerListScreenState();
}

class _ManagerListScreenState extends State<ManagerListScreen> {
  bool _showInactive = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ManagerProvider>().fetchManagers(includeInactive: _showInactive);
    });
  }

  void _refresh() {
    context.read<ManagerProvider>().fetchManagers(includeInactive: _showInactive);
  }

  void _openAddManager() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddEditManagerScreen()),
    ).then((_) => _refresh());
  }

  void _openEditManager(Manager manager) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddEditManagerScreen(manager: manager)),
    );
    // No _refresh() here — updateManager() already updates _managers[idx] in place.
    // Calling _refresh() would overwrite the locally-correct data with potentially
    // stale backend data (e.g. if the backend subdocument merge has an issue).
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manager Management'),
        backgroundColor: Colors.teal.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refresh),
          IconButton(
            icon: const Icon(Icons.person_add),
            tooltip: 'Add Manager',
            onPressed: _openAddManager,
          ),
        ],
      ),
      body: Consumer<ManagerProvider>(
        builder: (context, provider, _) {
          return Column(
            children: [
              // Toggle inactive
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    const Text('Show inactive managers'),
                    const Spacer(),
                    Switch(
                      value: _showInactive,
                      activeColor: Colors.teal,
                      onChanged: (val) {
                        setState(() => _showInactive = val);
                        _refresh();
                      },
                    ),
                  ],
                ),
              ),
              if (provider.error.isNotEmpty)
                Container(
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red.shade600),
                      const SizedBox(width: 8),
                      Expanded(child: Text(provider.error, style: TextStyle(color: Colors.red.shade700))),
                      IconButton(icon: const Icon(Icons.close), onPressed: provider.clearError),
                    ],
                  ),
                ),
              Expanded(
                child: provider.isLoading && provider.managers.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : provider.managers.isEmpty
                        ? _buildEmpty()
                        : RefreshIndicator(
                            onRefresh: () async => _refresh(),
                            child: ListView.builder(
                              itemCount: provider.managers.length,
                              itemBuilder: (context, index) {
                                return _buildManagerCard(provider.managers[index]);
                              },
                            ),
                          ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.teal.shade700,
        foregroundColor: Colors.white,
        onPressed: _openAddManager,
        child: const Icon(Icons.person_add),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.manage_accounts_outlined, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          const Text('No managers found', style: TextStyle(fontSize: 18, color: Colors.grey)),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: _openAddManager,
            icon: const Icon(Icons.person_add),
            label: const Text('Add First Manager'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal.shade700, foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildManagerCard(Manager manager) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                      Text(manager.name,
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                      Text(manager.email,
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                    ],
                  ),
                ),
                Row(
                  children: [
                    _buildStatusBadge(manager.isActive),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.teal),
                      onPressed: () => _openEditManager(manager),
                    ),
                  ],
                ),
              ],
            ),
            if (manager.phone != null && manager.phone!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(children: [
                Icon(Icons.phone, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(manager.phone!, style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
              ]),
            ],
            if (manager.assignedLocationNames.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: manager.assignedLocationNames.map((loc) => Chip(
                  label: Text(loc, style: const TextStyle(fontSize: 11)),
                  backgroundColor: Colors.teal.shade50,
                  side: BorderSide(color: Colors.teal.shade200),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                )).toList(),
              ),
            ] else if (manager.assignedLocationIds.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('${manager.assignedLocationIds.length} location(s) assigned',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
            ],
            const SizedBox(height: 8),
            _buildNotifRow(manager.notificationPreferences),
          ],
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
        border: Border.all(color: isActive ? Colors.green.shade300 : Colors.red.shade300),
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

  Widget _buildNotifRow(ManagerNotificationPreferences prefs) {
    final items = [
      ('Stock', prefs.stock, Icons.inventory_2_outlined),
      ('Repair', prefs.repair, Icons.build_outlined),
      ('Disposal', prefs.disposal, Icons.delete_outline),
      ('Transfer', prefs.transfer, Icons.compare_arrows),
    ];
    return Row(
      children: [
        Icon(Icons.email_outlined, size: 14, color: Colors.grey.shade500),
        const SizedBox(width: 4),
        Text('Emails: ', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        ...items.map((item) => Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Tooltip(
                message: '${item.$1} notifications ${item.$2 ? "on" : "off"}',
                child: Icon(
                  item.$3,
                  size: 16,
                  color: item.$2 ? Colors.teal : Colors.grey.shade300,
                ),
              ),
            )),
      ],
    );
  }
}
