import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  final _consumerNumberController = TextEditingController();
  final _meterNumberController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pinCodeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String _connectionType = 'Residential';
  final bool _isPasswordHidden = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _consumerNumberController.dispose();
    _meterNumberController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pinCodeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() => _errorMessage = 'Passwords do not match');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final msg = await AuthService.register(
        fullName: _nameController.text,
        email: _emailController.text,
        mobileNumber: _mobileController.text,
        consumerNumber: _consumerNumberController.text,
        meterNumber: _meterNumberController.text,
        connectionType: _connectionType,
        address: _addressController.text,
        city: _cityController.text,
        state: _stateController.text,
        pinCode: _pinCodeController.text,
        password: _passwordController.text,
      );

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: AppColors.cardBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Icon(Icons.check_circle, color: AppColors.success, size: 56),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Registration Successful!',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                msg,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // close dialog
                  Navigator.pop(context); // back to login
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Proceed to Login'),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Create Consumer Account', style: TextStyle(color: Colors.white)),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.border),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.dangerBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.danger.withValues(alpha: 0.5)),
                          ),
                          child: Text(_errorMessage!, style: const TextStyle(color: Colors.white, fontSize: 13)),
                        ),
                        const SizedBox(height: 16),
                      ],

                      CustomTextField(
                        controller: _nameController,
                        label: 'Full Name',
                        hint: 'John Doe',
                        prefixIcon: Icons.person_outline,
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter your full name' : null,
                      ),
                      const SizedBox(height: 14),

                      CustomTextField(
                        controller: _emailController,
                        label: 'Email Address',
                        hint: 'john@example.com',
                        prefixIcon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) => (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
                      ),
                      const SizedBox(height: 14),

                      CustomTextField(
                        controller: _mobileController,
                        label: 'Mobile Number',
                        hint: '9876543210',
                        prefixIcon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        validator: (v) => (v == null || v.trim().length < 10) ? 'Enter valid 10-digit mobile' : null,
                      ),
                      const SizedBox(height: 14),

                      Row(
                        children: [
                          Expanded(
                            child: CustomTextField(
                              controller: _consumerNumberController,
                              label: 'Consumer No.',
                              hint: '987654321012',
                              prefixIcon: Icons.confirmation_number_outlined,
                              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: CustomTextField(
                              controller: _meterNumberController,
                              label: 'Meter No.',
                              hint: 'MTR564879',
                              prefixIcon: Icons.electric_meter_outlined,
                              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Connection Type Dropdown
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Connection Type',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: AppColors.cardBgLight,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _connectionType,
                                isExpanded: true,
                                dropdownColor: AppColors.backgroundSecondary,
                                style: const TextStyle(color: Colors.white, fontSize: 15),
                                icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.primary),
                                items: const [
                                  DropdownMenuItem(value: 'Residential', child: Text('Residential')),
                                  DropdownMenuItem(value: 'Commercial', child: Text('Commercial')),
                                  DropdownMenuItem(value: 'Industrial', child: Text('Industrial')),
                                ],
                                onChanged: (val) {
                                  if (val != null) setState(() => _connectionType = val);
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      CustomTextField(
                        controller: _addressController,
                        label: 'Address',
                        hint: 'Flat/Street, Area',
                        prefixIcon: Icons.location_on_outlined,
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter address' : null,
                      ),
                      const SizedBox(height: 14),

                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: CustomTextField(
                              controller: _cityController,
                              label: 'City',
                              hint: 'Pune',
                              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: CustomTextField(
                              controller: _stateController,
                              label: 'State',
                              hint: 'Maharashtra',
                              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: CustomTextField(
                              controller: _pinCodeController,
                              label: 'PIN',
                              hint: '411001',
                              keyboardType: TextInputType.number,
                              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      CustomTextField(
                        controller: _passwordController,
                        label: 'Password',
                        hint: 'At least 5 characters',
                        prefixIcon: Icons.lock_outline,
                        obscureText: _isPasswordHidden,
                        validator: (v) => (v == null || v.length < 5) ? 'Min 5 characters' : null,
                      ),
                      const SizedBox(height: 14),

                      CustomTextField(
                        controller: _confirmPasswordController,
                        label: 'Confirm Password',
                        hint: 'Re-enter your password',
                        prefixIcon: Icons.lock_reset,
                        obscureText: _isPasswordHidden,
                        validator: (v) => (v == null || v.isEmpty) ? 'Confirm password' : null,
                      ),
                      const SizedBox(height: 24),

                      CustomButton(
                        text: 'Register Account',
                        onPressed: _handleRegister,
                        isLoading: _isLoading,
                      ),
                      const SizedBox(height: 16),

                      Center(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                          child: const Text('Already have an account? Login'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
