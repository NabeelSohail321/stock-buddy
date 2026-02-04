import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stock_buddy/models/location_model.dart';
import 'package:stock_buddy/providers/location_provider.dart';

class AddEditLocationScreen extends StatefulWidget {
  final Location? location;

  const AddEditLocationScreen({super.key, this.location});

  @override
  State<AddEditLocationScreen> createState() => _AddEditLocationScreenState();
}

class _AddEditLocationScreenState extends State<AddEditLocationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    if (widget.location != null) {
      _nameController.text = widget.location!.name;
      _addressController.text = widget.location!.address ?? '';
      _isActive = widget.location!.isActive;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.location != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Location' : 'Add Location'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEditing ? 'Update Location Details' : 'Create New Location',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Location Name *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter location name';
                  }
                  if (value.length < 2) {
                    return 'Location name must be at least 2 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Address (Optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.home),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              if (isEditing)
                Card(
                  child: SwitchListTile(
                    title: const Text(
                      'Active Status',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: const Text('Active locations can be used for stock operations'),
                    value: _isActive,
                    onChanged: (value) {
                      setState(() {
                        _isActive = value;
                      });
                    },
                    secondary: Icon(
                      _isActive ? Icons.check_circle : Icons.remove_circle,
                      color: _isActive ? Colors.green : Colors.grey,
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              _buildSubmitButton(isEditing),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitButton(bool isEditing) {
    final locationProvider = context.watch<LocationProvider>();

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: locationProvider.isLoading ? null : _submitForm,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: isEditing ? Colors.orange : Colors.blue,
        ),
        child: locationProvider.isLoading
            ? const SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation(Colors.white),
          ),
        )
            : Text(
          isEditing ? 'Update Location' : 'Create Location',
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final locationProvider = context.read<LocationProvider>();
      final success = widget.location == null
          ? await locationProvider.createLocation(
        name: _nameController.text.trim(),
        address: _addressController.text.trim().isEmpty
            ? null
            : _addressController.text.trim(),
      )
          : await locationProvider.updateLocation(
        id: widget.location!.id,
        name: _nameController.text.trim(),
        address: _addressController.text.trim(),
        isActive: _isActive,
      );

      if (success && mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.location == null
                ? 'Location created successfully'
                : 'Location updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(locationProvider.error ?? 'Operation failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}