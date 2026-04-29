import 'package:flutter/material.dart';

import '../../../core/utils/validators.dart';
import '../../../services/auth_service.dart';
import '../../../services/repairman/repairman_service.dart';

class RepairmanVerificationPage extends StatefulWidget {
  const RepairmanVerificationPage({super.key});

  @override
  State<RepairmanVerificationPage> createState() =>
      _RepairmanVerificationPageState();
}

class _RepairmanVerificationPageState extends State<RepairmanVerificationPage> {
  final RepairmanService _repairmanService = RepairmanService();
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _idNumberController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _specializationController =
      TextEditingController();
  final TextEditingController _experienceController = TextEditingController();
  final TextEditingController _idProofUrlController = TextEditingController();
  final TextEditingController _addressProofUrlController =
      TextEditingController();
  final TextEditingController _skillCertificateUrlController =
      TextEditingController();
  final TextEditingController _selfieUrlController = TextEditingController();
  final TextEditingController _digilockerReferenceController =
      TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  bool _isLoading = true;
  bool _isSubmitting = false;
  String _idType = 'Aadhaar';
  String _status = 'unverified';
  String _rejectionReason = '';
  String _reviewedAt = '';

  @override
  void initState() {
    super.initState();
    _loadVerification();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _dobController.dispose();
    _idNumberController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _specializationController.dispose();
    _experienceController.dispose();
    _idProofUrlController.dispose();
    _addressProofUrlController.dispose();
    _skillCertificateUrlController.dispose();
    _selfieUrlController.dispose();
    _digilockerReferenceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadVerification() async {
    final session = AuthService.currentSession ?? const <String, dynamic>{};

    try {
      final response = await _repairmanService.getMyVerification();
      final verification = Map<String, dynamic>.from(
        (response['verification'] as Map?) ?? const <String, dynamic>{},
      );
      final profile = Map<String, dynamic>.from(
        (verification['profile'] as Map?) ?? const <String, dynamic>{},
      );
      final documents = Map<String, dynamic>.from(
        (verification['documents'] as Map?) ?? const <String, dynamic>{},
      );

      _fullNameController.text = (profile['full_name'] ?? session['name'] ?? '')
          .toString();
      _emailController.text = (profile['email'] ?? session['email'] ?? '')
          .toString();
      _dobController.text = (profile['date_of_birth'] ?? '').toString();
      _phoneController.text = (profile['phone'] ?? session['phone'] ?? '')
          .toString();
      _addressController.text = (profile['address'] ?? session['address'] ?? '')
          .toString();
      _cityController.text = (profile['city'] ?? session['city'] ?? '')
          .toString();
      _specializationController.text =
          (profile['specialization'] ?? session['specialization'] ?? '')
              .toString();
      _experienceController.text =
          '${profile['experience_years'] ?? session['experience'] ?? ''}';
      _idType = (documents['id_type'] ?? 'Aadhaar').toString();
      _idNumberController.text = (documents['id_last4'] ?? '').toString();
      _idProofUrlController.text = (documents['id_proof_url'] ?? '').toString();
      _addressProofUrlController.text = (documents['address_proof_url'] ?? '')
          .toString();
      _skillCertificateUrlController.text =
          (documents['skill_certificate_url'] ?? '').toString();
      _selfieUrlController.text = (documents['selfie_url'] ?? '').toString();
      _digilockerReferenceController.text =
          (documents['digilocker_reference'] ?? '').toString();
      _notesController.text = (profile['notes'] ?? '').toString();
      _status = (verification['status'] ?? 'unverified').toString();
      _rejectionReason = (verification['rejection_reason'] ?? '').toString();
      _reviewedAt = (verification['reviewed_at'] ?? '').toString();
    } catch (_) {
      _fullNameController.text = (session['name'] ?? '').toString();
      _emailController.text = (session['email'] ?? '').toString();
      _phoneController.text = (session['phone'] ?? '').toString();
      _addressController.text = (session['address'] ?? '').toString();
      _cityController.text = (session['city'] ?? '').toString();
      _specializationController.text = (session['specialization'] ?? '')
          .toString();
      _experienceController.text = '${session['experience'] ?? ''}';
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _statusLabel(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized.isEmpty) return 'Unverified';
    return normalized
        .replaceAll('_', ' ')
        .split(' ')
        .map(
          (word) => word.isEmpty
              ? word
              : '${word[0].toUpperCase()}${word.substring(1)}',
        )
        .join(' ');
  }

  Color _statusColor(String value) {
    switch (value.trim().toLowerCase()) {
      case 'verified':
        return const Color(0xFF2E7D32);
      case 'pending':
      case 'under_review':
        return const Color(0xFFE05A2A);
      case 'rejected':
        return const Color(0xFFC62828);
      default:
        return const Color(0xFF6B7280);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final response = await _repairmanService.submitMyVerification({
        'full_name': _fullNameController.text.trim(),
        'email': _emailController.text.trim(),
        'date_of_birth': _dobController.text.trim(),
        'id_type': _idType,
        'id_number': _idNumberController.text.trim(),
        'phone': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'city': _cityController.text.trim(),
        'specialization': _specializationController.text.trim(),
        'experience_years':
            int.tryParse(_experienceController.text.trim()) ?? 0,
        'id_proof_url': _idProofUrlController.text.trim(),
        'address_proof_url': _addressProofUrlController.text.trim(),
        'skill_certificate_url': _skillCertificateUrlController.text.trim(),
        'selfie_url': _selfieUrlController.text.trim(),
        'digilocker_reference': _digilockerReferenceController.text.trim(),
        'notes': _notesController.text.trim(),
      });

      final verification = Map<String, dynamic>.from(
        (response['verification'] as Map?) ?? const <String, dynamic>{},
      );

      await AuthService.updateSessionData({
        'verification_status': verification['status'] ?? 'pending',
        'is_verified': verification['is_verified'] == true,
      });

      if (!mounted) return;
      setState(() {
        _status = (verification['status'] ?? 'pending').toString();
        _rejectionReason = '';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verification submitted for review.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Widget _buildTextField(
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
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verification'),
        backgroundColor: const Color(0xFF4A90E2),
      ),
      backgroundColor: const Color(0xFFF4F7FA),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Verification Status',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: _statusColor(_status).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          _statusLabel(_status),
                          style: TextStyle(
                            color: _statusColor(_status),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (_reviewedAt.trim().isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text('Reviewed at: $_reviewedAt'),
                      ],
                      if (_rejectionReason.trim().isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(
                          'Reason: $_rejectionReason',
                          style: const TextStyle(color: Color(0xFFC62828)),
                        ),
                      ],
                      const SizedBox(height: 12),
                      const Text(
                        'Use this screen to submit identity, address, selfie, and trade proof for admin review. DigiLocker reference can be added later if you onboard it.',
                        style: TextStyle(color: Color(0xFF6B7280)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
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
                          'Submit Verification',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          'Email',
                          _emailController,
                          keyboardType: TextInputType.emailAddress,
                          validator: Validators.validateEmail,
                        ),
                        _buildTextField(
                          'Full Name',
                          _fullNameController,
                          validator: (value) =>
                              (value == null || value.trim().isEmpty)
                              ? 'Full name is required'
                              : null,
                        ),
                        _buildTextField(
                          'Date of Birth',
                          _dobController,
                          hint: 'YYYY-MM-DD',
                        ),
                        DropdownButtonFormField<String>(
                          initialValue: _idType,
                          decoration: InputDecoration(
                            labelText: 'ID Type',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'Aadhaar',
                              child: Text('Aadhaar'),
                            ),
                            DropdownMenuItem(value: 'PAN', child: Text('PAN')),
                            DropdownMenuItem(
                              value: 'Driving License',
                              child: Text('Driving License'),
                            ),
                            DropdownMenuItem(
                              value: 'Voter ID',
                              child: Text('Voter ID'),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _idType = value ?? 'Aadhaar';
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        _buildTextField(
                          'ID Number',
                          _idNumberController,
                          validator: (value) =>
                              (value == null || value.trim().isEmpty)
                              ? 'ID number is required'
                              : null,
                        ),
                        _buildTextField(
                          'Phone',
                          _phoneController,
                          keyboardType: TextInputType.phone,
                          validator: Validators.validatePhone,
                        ),
                        _buildTextField(
                          'Address',
                          _addressController,
                          maxLines: 2,
                        ),
                        _buildTextField('City', _cityController),
                        _buildTextField(
                          'Specialization',
                          _specializationController,
                        ),
                        _buildTextField(
                          'Experience (Years)',
                          _experienceController,
                          keyboardType: TextInputType.number,
                        ),
                        _buildTextField('ID Proof URL', _idProofUrlController),
                        _buildTextField(
                          'Address Proof URL',
                          _addressProofUrlController,
                        ),
                        _buildTextField(
                          'Skill Certificate URL',
                          _skillCertificateUrlController,
                        ),
                        _buildTextField('Selfie URL', _selfieUrlController),
                        _buildTextField(
                          'DigiLocker Reference',
                          _digilockerReferenceController,
                          hint: 'Optional for future integration',
                        ),
                        _buildTextField('Notes', _notesController, maxLines: 3),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isSubmitting ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2E6BE6),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: _isSubmitting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Text('Submit for Review'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
