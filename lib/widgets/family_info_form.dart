import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/family_info_model.dart';
import '../services/family_info_service.dart';
import '../theme.dart';

class FamilyInfoForm extends StatefulWidget {
  final VoidCallback onComplete;

  const FamilyInfoForm({super.key, required this.onComplete});

  @override
  State<FamilyInfoForm> createState() => _FamilyInfoFormState();
}

class _FamilyInfoFormState extends State<FamilyInfoForm> {
  final _formKey = GlobalKey<FormState>();
  final _service = FamilyInfoService();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _childrenController = TextEditingController();
  final _womenController = TextEditingController();
  final _elderlyController = TextEditingController();
  final _addressController = TextEditingController();

  bool _isSubmitting = false;
  bool _showSuccess = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _childrenController.dispose();
    _womenController.dispose();
    _elderlyController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final info = FamilyInfo(
      headOfFamilyName: _nameController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      numberOfChildren: int.tryParse(_childrenController.text.trim()),
      numberOfWomen: int.tryParse(_womenController.text.trim()),
      numberOfElderly: int.tryParse(_elderlyController.text.trim()),
      address: _addressController.text.trim(),
      submittedAt: DateTime.now(),
    );

    await _service.saveFamilyInfo(info);

    setState(() {
      _isSubmitting = false;
      _showSuccess = true;
    });

    // Wait 3 seconds then close
    await Future.delayed(const Duration(seconds: 3));
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      body: SafeArea(
        child: _showSuccess ? _buildSuccessScreen() : _buildForm(),
      ),
    );
  }

  Widget _buildSuccessScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withValues(alpha: 0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 60),
            ),
            const SizedBox(height: 32),
            const Text(
              'আপনার তথ্য সফলভাবে জমা হয়েছে',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0D1B2A),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'আপনার তথ্য সরকারের কাছে পাঠানো হয়েছে এবং বিপদের সময় ব্যবহার করা হবে',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF6C757D),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1565C0).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.family_restroom,
                  size: 60,
                  color: Color(0xFF1565C0),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'পরিবারের তথ্য',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0D1B2A),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'জরুরি অবস্থায় আপনাকে সাহায্য করার জন্য পরিবারের তথ্য প্রদান করুন',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF6C757D),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            _buildTextField(
              controller: _nameController,
              label: 'পরিবার প্রধানের নাম',
              icon: Icons.person_outline,
              validator: (v) => v?.isEmpty ?? true ? 'নাম প্রদান করুন' : null,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _phoneController,
              label: 'মোবাইল নম্বর',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              validator: (v) => v?.isEmpty ?? true
                  ? 'মোবাইল নম্বর প্রদান করুন'
                  : (v!.length < 11 ? 'সঠিক নম্বর প্রদান করুন' : null),
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _childrenController,
              label: 'শিশুর সংখ্যা (১৮ বছরের নিচে)',
              icon: Icons.child_care_outlined,
              keyboardType: TextInputType.number,
              required: false,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _womenController,
              label: 'মহিলার সংখ্যা',
              icon: Icons.woman_outlined,
              keyboardType: TextInputType.number,
              required: false,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _elderlyController,
              label: 'বয়স্ক ব্যক্তির সংখ্যা (৬০+ বছর)',
              icon: Icons.elderly_outlined,
              keyboardType: TextInputType.number,
              required: false,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _addressController,
              label: 'ঠিকানা',
              icon: Icons.home_outlined,
              maxLines: 3,
              required: false,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1565C0),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 4,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'জমা দিন',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
    bool required = true,
  }) {
    return GlassCard(
      borderRadius: BorderRadius.circular(14),
      padding: EdgeInsets.zero,
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: required ? validator : null,
        inputFormatters: keyboardType == TextInputType.number
            ? [FilteringTextInputFormatter.digitsOnly]
            : null,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: const Color(0xFF1565C0)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.9),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
        style: const TextStyle(fontSize: 15, color: Color(0xFF0D1B2A)),
      ),
    );
  }
}
