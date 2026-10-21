import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../shared/providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(authProvider.notifier).signUp(
          _emailController.text,
          _passwordController.text,
          _nameController.text,
        );

    if (success && mounted) {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ចុះឈ្មោះគណនីថ្មី'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.asset(
                      'assets/icons/app_icon.png',
                      width: 72,
                      height: 72,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (authState.error != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.errorContainer.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        authState.error!.message,
                        style: const TextStyle(color: AppColors.error, fontSize: 13),
                      ),
                    ),
                    const SizedBox(height: 18),
                  ],

                  // Display Name
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'ឈ្មោះរបស់អ្នក (Display Name)',
                      prefixIcon: Icon(Icons.person_outline_rounded, color: AppColors.secondary),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'សូមបញ្ចូលឈ្មោះរបស់អ្នក';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Email
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'អ៊ីមែល (Email)',
                      prefixIcon: Icon(Icons.email_outlined, color: AppColors.secondary),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'សូមបញ្ចូលអ៊ីមែល';
                      }
                      if (!val.contains('@')) {
                        return 'ទម្រង់អ៊ីមែលមិនត្រឹមត្រូវទេ';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Password
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'ពាក្យសម្ងាត់ (Password)',
                      prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.secondary),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                          color: AppColors.textTertiary,
                        ),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    validator: (val) {
                      if (val == null || val.length < 6) {
                        return 'ពាក្យសម្ងាត់ត្រូវមានយ៉ាងហោចណាស់ ៦ តួអក្សរ';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Confirm Password
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscurePassword,
                    decoration: const InputDecoration(
                      labelText: 'ផ្ទៀងផ្ទាត់ពាក្យសម្ងាត់ (Confirm Password)',
                      prefixIcon: Icon(Icons.lock_reset_rounded, color: AppColors.secondary),
                    ),
                    validator: (val) {
                      if (val != _passwordController.text) {
                        return 'ពាក្យសម្ងាត់មិនត្រូវគ្នាទេ';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 28),

                  // Submit
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: authState.isLoading ? null : _handleRegister,
                      child: authState.isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('បង្កើតគណនី (Sign Up)'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
