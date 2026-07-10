import 'package:ethiopian_food_app/core/auth/auth_error_messages.dart';
import 'package:ethiopian_food_app/core/providers/auth_provider.dart';
import 'package:ethiopian_food_app/features/auth/widgets/auth_message_banner.dart';
import 'package:ethiopian_food_app/features/auth/widgets/auth_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLogin = true;
  bool _isSubmitting = false;
  String? _errorMessage;
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      if (_isLogin) {
        await ref.read(authStateProvider.notifier).login(
          _emailController.text.trim(),
          _passwordController.text,
        );
      } else {
        await ref.read(authStateProvider.notifier).register(
          _fullNameController.text.trim(),
          _emailController.text.trim(),
          _passwordController.text,
        );
      }

      if (!mounted) return;

      final authState = ref.read(authStateProvider);
      authState.whenOrNull(
        data: (user) {
          if (user != null) {
            if (user.needsSetup) {
              context.go('/onboarding');
            } else {
              context.go('/dashboard');
            }
          }
        },
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = mapAuthErrorMessage(error, isLogin: _isLogin);
      });
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _toggleAuthMode() {
    setState(() {
      _isLogin = !_isLogin;
      _errorMessage = null;
    });
  }

  bool _isValidEmail(String value) {
    return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value);
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      title: _isLogin ? 'Welcome back' : 'Create your account',
      subtitle: _isLogin
          ? 'Sign in to continue tracking your nutrition.'
          : 'Join the app to save meals and get personalized guidance.',
      footer: null,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!_isLogin)
              TextFormField(
                controller: _fullNameController,
                decoration: const InputDecoration(
                  labelText: 'Full name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Please enter your full name.'
                    : null,
              ),
            if (!_isLogin) const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your email address.';
                }
                if (!_isValidEmail(value.trim())) {
                  return 'Please enter a valid email address.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                prefixIcon: Icon(Icons.lock_outline),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your password.';
                }
                if (!_isLogin && value.length < 8) {
                  return kPasswordRequirementsMessage;
                }
                return null;
              },
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              AuthMessageBanner(message: _errorMessage!),
            ],
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _isSubmitting ? null : _submit,
              icon: _isSubmitting
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    )
                  : Icon(_isLogin ? Icons.login_rounded : Icons.person_add_rounded),
              label: Text(_isLogin ? 'Sign in' : 'Create account'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _isSubmitting ? null : _toggleAuthMode,
              child: Text(_isLogin ? 'Need an account? Sign up' : 'Already have an account? Sign in'),
            ),
          ],
        ),
      ),
    );
  }
}
