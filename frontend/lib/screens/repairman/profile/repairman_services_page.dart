import 'package:flutter/material.dart';

import '../../../core/utils/money_utils.dart';
import '../../../services/auth_service.dart';
import '../../../services/repairman/repairman_service.dart';

class RepairmanServicesPage extends StatefulWidget {
  const RepairmanServicesPage({super.key});

  @override
  State<RepairmanServicesPage> createState() => _RepairmanServicesPageState();
}

class _RepairmanServicesPageState extends State<RepairmanServicesPage> {
  final RepairmanService _repairmanService = RepairmanService();
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _serviceNameController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  bool _isLoading = true;
  bool _isSubmitting = false;
  List<Map<String, dynamic>> _services = const <Map<String, dynamic>>[];

  @override
  void initState() {
    super.initState();
    final session = AuthService.currentSession ?? const <String, dynamic>{};
    _categoryController.text =
        (session['specialization'] ?? session['category'] ?? '').toString();
    _loadServices();
  }

  @override
  void dispose() {
    _serviceNameController.dispose();
    _categoryController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _loadServices() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final services = await _repairmanService.getMyLinkedServices();
      if (!mounted) return;
      setState(() {
        _services = services;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  String _serviceTitle(Map<String, dynamic> item) {
    final name = (item['service_name'] ?? item['name'] ?? '').toString().trim();
    if (name.isNotEmpty) return name;

    final serviceId = (item['service_id'] ?? item['id'] ?? '').toString().trim();
    return serviceId.isNotEmpty ? 'Service $serviceId' : 'Custom service';
  }

  String _serviceCategory(Map<String, dynamic> item) {
    return (item['category'] ?? '').toString().trim();
  }

  String _serviceDescription(Map<String, dynamic> item) {
    return (item['description'] ?? '').toString().trim();
  }

  double _servicePrice(Map<String, dynamic> item) {
    final value = item['custom_price'];
    if (value is num) return value.toDouble();
    return double.tryParse('$value') ?? 0;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      await _repairmanService.addMyService(
        serviceName: _serviceNameController.text.trim(),
        category: _categoryController.text.trim(),
        description: _descriptionController.text.trim(),
        customPrice: double.tryParse(_priceController.text.trim()) ?? 0,
      );
      _serviceNameController.clear();
      _descriptionController.clear();
      _priceController.clear();
      await _loadServices();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Custom service added.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Widget _buildField(
    String label,
    TextEditingController controller, {
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  Widget _buildAddedServices() {
    if (_services.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text(
          'No services added yet. Add the exact work you offer, like wiring repair, fan installation, or switchboard fixing.',
          style: TextStyle(
            color: Color(0xFF6B7280),
            fontSize: 14,
          ),
        ),
      );
    }

    return Column(
      children: _services.map((item) {
        final title = _serviceTitle(item);
        final category = _serviceCategory(item);
        final description = _serviceDescription(item);
        final price = _servicePrice(item);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Color(0x11000000),
                blurRadius: 14,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ),
                  if (price > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F1FF),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        MoneyUtils.format(price),
                        style: const TextStyle(
                          color: Color(0xFF1F3B73),
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
              if (category.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  category,
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 12,
                  ),
                ),
              ],
              if (description.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  description,
                  style: const TextStyle(
                    color: Color(0xFF4B5563),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Services'),
        backgroundColor: const Color(0xFF4A90E2),
      ),
      backgroundColor: const Color(0xFFF4F7FA),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadServices,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Add Service You Offer',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF111827),
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Create your own service based on your field. Example: Electrical -> House wiring, Fan repair, MCB replacement.',
                            style: TextStyle(color: Color(0xFF6B7280)),
                          ),
                          const SizedBox(height: 16),
                          _buildField(
                            'Service Name',
                            _serviceNameController,
                            hint: 'Example: Fan repair',
                            validator: (value) =>
                                value == null || value.trim().isEmpty
                                ? 'Service name is required'
                                : null,
                          ),
                          _buildField(
                            'Field / Category',
                            _categoryController,
                            hint: 'Example: Electrical',
                            validator: (value) =>
                                value == null || value.trim().isEmpty
                                ? 'Category is required'
                                : null,
                          ),
                          _buildField(
                            'Description',
                            _descriptionController,
                            hint: 'Describe what this service covers',
                            maxLines: 3,
                          ),
                          _buildField(
                            'Price',
                            _priceController,
                            hint: 'Example: 400',
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            validator: (value) {
                              final amount = double.tryParse((value ?? '').trim());
                              if (amount == null || amount <= 0) {
                                return 'Enter a valid price';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: _isSubmitting ? null : _submit,
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF2E6BE6),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: _isSubmitting
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                  : const Text('Add Custom Service'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    'Added Services',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildAddedServices(),
                ],
              ),
            ),
    );
  }
}
