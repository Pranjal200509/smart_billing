import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../services/auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  int _currentStep = 1; // 1: Email, 2: OTP, 3: New Password
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String? _resetToken;
  bool _isLoading = false;
  String? _message;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSendOtp() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = 'Enter a valid registered email address');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _message = null;
    });

    try {
      final msg = await AuthService.forgotPassword(email);
      setState(() {
        _message = msg;
        _currentStep = 2;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleVerifyOtp() async {
    final otp = _otpController.text.trim();
    if (otp.isEmpty || otp.length < 6) {
      setState(() => _error = 'Enter the 6-digit OTP code');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final token = await AuthService.verifyOtp(_emailController.text.trim(), otp);
      setState(() {
        _resetToken = token;
        _currentStep = 3;
        _message = 'OTP Verified. Set your new password.';
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleResetPassword() async {
    final newPass = _newPasswordController.text;
    final confirmPass = _confirmPasswordController.text;

    if (newPass.length < 5) {
      setState(() => _error = 'Password must be at least 5 characters');
      return;
    }

    if (newPass != confirmPass) {
      setState(() => _error = 'Passwords do not match');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final msg = await AuthService.resetPassword(
        email: _emailController.text.trim(),
        token: _resetToken!,
        newPassword: newPass,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: AppColors.success),
      );

      Navigator.pop(context); // return to login
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
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
        title: const Text('Account Recovery', style: TextStyle(color: Colors.white)),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.lock_reset, size: 40, color: AppColors.primary),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _currentStep == 1
                          ? 'Forgot Password'
                          : _currentStep == 2
                              ? 'Enter OTP Code'
                              : 'Set New Password',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _currentStep == 1
                          ? 'Enter your registered email to receive an OTP code'
                          : _currentStep == 2
                              ? 'Check the backend console output for the simulated OTP'
                              : 'Create a new secure password for your account',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),

                    if (_error != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.dangerBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.danger.withValues(alpha: 0.5)),
                        ),
                        child: Text(_error!, style: const TextStyle(color: Colors.white, fontSize: 13)),
                      ),
                      const SizedBox(height: 16),
                    ],

                    if (_message != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.successBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.success.withValues(alpha: 0.5)),
                        ),
                        child: Text(_message!, style: const TextStyle(color: Colors.white, fontSize: 13)),
                      ),
                      const SizedBox(height: 16),
                    ],

                    if (_currentStep == 1) ...[
                      CustomTextField(
                        controller: _emailController,
                        label: 'Registered Email',
                        hint: 'name@example.com',
                        prefixIcon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 24),
                      CustomButton(
                        text: 'Send OTP Code',
                        onPressed: _handleSendOtp,
                        isLoading: _isLoading,
                      ),
                    ] else if (_currentStep == 2) ...[
                      CustomTextField(
                        controller: _otpController,
                        label: '6-Digit OTP',
                        hint: '123456',
                        prefixIcon: Icons.pin_outlined,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 24),
                      CustomButton(
                        text: 'Verify OTP',
                        onPressed: _handleVerifyOtp,
                        isLoading: _isLoading,
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => setState(() => _currentStep = 1),
                        style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
                        child: const Text('Change Email'),
                      ),
                    ] else if (_currentStep == 3) ...[
                      CustomTextField(
                        controller: _newPasswordController,
                        label: 'New Password',
                        hint: 'At least 5 characters',
                        prefixIcon: Icons.lock_outline,
                        obscureText: true,
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _confirmPasswordController,
                        label: 'Confirm New Password',
                        hint: 'Re-enter password',
                        prefixIcon: Icons.lock_reset,
                        obscureText: true,
                      ),
                      const SizedBox(height: 24),
                      CustomButton(
                        text: 'Reset Password',
                        onPressed: _handleResetPassword,
                        isLoading: _isLoading,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
