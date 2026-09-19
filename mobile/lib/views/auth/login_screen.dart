import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../../core/constants/app_colors.dart';
import '../../core/storage/session_manager.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../services/auth_service.dart';
import '../admin/admin_shell.dart';
import '../consumer/consumer_shell.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordHidden = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final jwtResponse = await AuthService.login(
        _emailController.text,
        _passwordController.text,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Welcome back, ${jwtResponse.fullName}!'),
          backgroundColor: AppColors.success,
        ),
      );

      if (jwtResponse.role == 'ROLE_ADMIN') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminShell()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ConsumerShell()),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _fillCredentials(String email, String password) {
    setState(() {
      _emailController.text = email;
      _passwordController.text = password;
      _errorMessage = null;
    });
  }

  void _showServerSettingsDialog() {
    final currentHost = ApiEndpoints.baseUrl.replaceAll('/api/v1', '');
    final urlController = TextEditingController(text: currentHost);
    bool testing = false;
    String? testResult;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.cardBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.border),
          ),
          title: const Row(
            children: [
              Icon(Icons.dns, color: AppColors.primary, size: 20),
              SizedBox(width: 8),
              Text('Backend Server URL', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Configure the Spring Boot backend address:',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  ActionChip(
                    label: const Text('💻 Web / Desktop (127.0.0.1)', style: TextStyle(fontSize: 11, color: Colors.white)),
                    backgroundColor: AppColors.backgroundSecondary,
                    side: const BorderSide(color: AppColors.primary),
                    onPressed: () => setDialogState(() => urlController.text = 'http://127.0.0.1:8080'),
                  ),
                  ActionChip(
                    label: const Text('🤖 Emulator (10.0.2.2)', style: TextStyle(fontSize: 11, color: Colors.white)),
                    backgroundColor: AppColors.backgroundSecondary,
                    side: const BorderSide(color: AppColors.accent),
                    onPressed: () => setDialogState(() => urlController.text = 'http://10.0.2.2:8080'),
                  ),
                  ActionChip(
                    label: Text('📱 Physical Device (${ApiEndpoints.localLanIp})', style: const TextStyle(fontSize: 11, color: Colors.white)),
                    backgroundColor: AppColors.backgroundSecondary,
                    side: const BorderSide(color: AppColors.success),
                    onPressed: () => setDialogState(() => urlController.text = 'http://${ApiEndpoints.localLanIp}:8080'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: urlController,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  labelText: 'Host URL',
                  hintText: 'http://127.0.0.1:8080',
                  labelStyle: const TextStyle(color: AppColors.primary),
                  hintStyle: const TextStyle(color: AppColors.textMuted),
                  filled: true,
                  fillColor: AppColors.backgroundSecondary,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary)),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: testing ? null : () async {
                      setDialogState(() {
                        testing = true;
                        testResult = null;
                      });
                      try {
                        var target = urlController.text.trim();
                        if (target.endsWith('/')) target = target.substring(0, target.length - 1);
                        if (!target.endsWith('/api/v1')) target = '$target/api/v1';
                        final result = await ApiClient.get('$target/health', requiresAuth: false);
                        final serverStatus = (result is Map) ? result['status'] ?? 'UP' : 'UP';
                        setDialogState(() {
                          testing = false;
                          testResult = '✅ Server is $serverStatus at $target';
                        });
                      } catch (e) {
                        setDialogState(() {
                          testing = false;
                          testResult = '❌ Failed: ${e.toString().split('\n').first}';
                        });
                      }
                    },
                    icon: testing
                        ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent))
                        : const Icon(Icons.wifi, size: 14, color: AppColors.accent),
                    label: const Text('Test Connection', style: TextStyle(fontSize: 11, color: AppColors.accent)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.accent),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () {
                      urlController.text = ApiEndpoints.defaultHost;
                    },
                    child: const Text('Reset Default', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                  ),
                ],
              ),
              if (testResult != null) ...[
                const SizedBox(height: 8),
                Text(
                  testResult!,
                  style: TextStyle(
                    color: testResult!.startsWith('✅') ? AppColors.success : Colors.redAccent,
                    fontSize: 11,
                  ),
                ),
              ],
              const SizedBox(height: 4),
              const Text(
                '💡 Emulator → 10.0.2.2:8080   Physical Device → PC LAN IP:8080   Web/Desktop → 127.0.0.1:8080',
                style: TextStyle(color: AppColors.textMuted, fontSize: 10),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
            ),
            ElevatedButton(
              onPressed: () async {
                final newUrl = urlController.text.trim();
                ApiEndpoints.setBaseUrl(newUrl);
                await SessionManager.setCustomBaseUrl(newUrl);
                // Reset so next request re-reads the new URL from storage
                ApiClient.resetInitialization();
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(
                    content: Text('Server URL set to: ${ApiEndpoints.baseUrl}'),
                    backgroundColor: AppColors.success,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const SizedBox(width: 32),
                          Center(
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(alpha: 0.3),
                                    blurRadius: 16,
                                    spreadRadius: 4,
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.electric_bolt, size: 40, color: AppColors.primary),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.settings_outlined, color: AppColors.textMuted, size: 20),
                            tooltip: 'Server Settings',
                            onPressed: _showServerSettingsDialog,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Welcome Back',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Sign in with your registered account',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 24),

                      if (_errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.dangerBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.danger.withValues(alpha: 0.5)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline, color: AppColors.danger, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(color: Colors.white, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      CustomTextField(
                        controller: _emailController,
                        label: 'Email Address',
                        hint: 'name@example.com',
                        prefixIcon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return 'Please enter your email';
                          if (!val.contains('@')) return 'Enter a valid email address';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      CustomTextField(
                        controller: _passwordController,
                        label: 'Password',
                        hint: 'Enter your password',
                        prefixIcon: Icons.lock_outline,
                        obscureText: _isPasswordHidden,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordHidden ? Icons.visibility_off : Icons.visibility,
                            color: AppColors.primary,
                            size: 20,
                          ),
                          onPressed: () => setState(() => _isPasswordHidden = !_isPasswordHidden),
                        ),
                        validator: (val) {
                          if (val == null || val.isEmpty) return 'Please enter your password';
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),

                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                            );
                          },
                          style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                          child: const Text('Forgot Password?', style: TextStyle(fontSize: 13)),
                        ),
                      ),
                      const SizedBox(height: 16),

                      CustomButton(
                        text: 'Sign In',
                        onPressed: _handleLogin,
                        isLoading: _isLoading,
                      ),
                      const SizedBox(height: 20),

                      // Quick Demo Logins
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.cardBgLight,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'QUICK DEMO ACCOUNTS',
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => _fillCredentials('pranjalpawar@gmail.com', '12345'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.accent,
                                      side: const BorderSide(color: AppColors.accent),
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                    child: const Text('Consumer', style: TextStyle(fontSize: 12)),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => _fillCredentials('admin@gmail.com', '12345'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.primary,
                                      side: const BorderSide(color: AppColors.primary),
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                    child: const Text('Admin', style: TextStyle(fontSize: 12)),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("Don't have an account?", style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const RegisterScreen()),
                              );
                            },
                            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                            child: const Text('Register', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
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
