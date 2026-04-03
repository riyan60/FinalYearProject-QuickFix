import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../services/feedback_service.dart';

class FeedbackContactPage extends StatefulWidget {
  final String initialFeedbackType;

  const FeedbackContactPage({
    super.key,
    this.initialFeedbackType = 'user',
  });

  @override
  State<FeedbackContactPage> createState() => _FeedbackContactPageState();
}

class _FeedbackContactPageState extends State<FeedbackContactPage> {
  final _formKey = GlobalKey<FormState>();
  final FeedbackService _feedbackService = FeedbackService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  late String _feedbackType;
  String _subject = 'General experience';
  int _rating = 5;
  bool _isSubmitting = false;

  static const List<String> _subjects = <String>[
    'General experience',
    'Booking issue',
    'Payment issue',
    'App bug',
    'Support request',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _feedbackType = widget.initialFeedbackType == 'repairman'
        ? 'repairman'
        : 'user';
    final session = AuthService.currentSession ?? const <String, dynamic>{};
    _nameController.text = (session['name'] ?? '').toString();
    _phoneController.text = (session['phone'] ?? '').toString();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      await _feedbackService.submitFeedback(
        feedbackType: _feedbackType,
        subject: _subject,
        message: _messageController.text.trim(),
        contactName: _nameController.text.trim(),
        contactPhone: _phoneController.text.trim(),
        rating: _rating,
      );

      if (!mounted) return;
      _messageController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Feedback submitted. Thank you!')),
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

  Widget _buildContactTile({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: const Color(0xFF3559A8)),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(value),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Feedback & Contact'),
        backgroundColor: const Color(0xFF4A90E2),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'QuickFix Contacts',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildContactTile(
                      icon: Icons.phone_outlined,
                      title: 'Support Number',
                      value: '8007194157',
                    ),
                    _buildContactTile(
                      icon: Icons.email_outlined,
                      title: 'Support Email',
                      value: 'support@quickfix.app',
                    ),
                    _buildContactTile(
                      icon: Icons.schedule_outlined,
                      title: 'Support Hours',
                      value: 'Mon-Sat, 9:00 AM - 8:00 PM',
                    ),
                    _buildContactTile(
                      icon: Icons.chat_outlined,
                      title: 'WhatsApp',
                      value: '+91 8007194157',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Send Feedback',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _feedbackType,
                        decoration: const InputDecoration(
                          labelText: 'Feedback For',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'user', child: Text('User')),
                          DropdownMenuItem(
                            value: 'repairman',
                            child: Text('Repairman'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() {
                            _feedbackType = value;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _subject,
                        decoration: const InputDecoration(
                          labelText: 'Subject',
                          border: OutlineInputBorder(),
                        ),
                        items: _subjects
                            .map(
                              (subject) => DropdownMenuItem<String>(
                                value: subject,
                                child: Text(subject),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() {
                            _subject = value;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Your Name',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Enter your name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Contact Number',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Enter a contact number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _messageController,
                        minLines: 4,
                        maxLines: 6,
                        decoration: const InputDecoration(
                          labelText: 'Your Feedback',
                          alignLabelWithHint: true,
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().length < 10) {
                            return 'Please enter at least 10 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      Text('Rating: $_rating/5'),
                      Slider(
                        min: 1,
                        max: 5,
                        divisions: 4,
                        value: _rating.toDouble(),
                        onChanged: (value) {
                          setState(() {
                            _rating = value.round();
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _submit,
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Submit Feedback'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
