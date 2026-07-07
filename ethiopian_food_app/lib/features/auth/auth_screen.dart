import 'package:ethiopian_food_app/core/api/api_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ethiopian_food_app/core/providers/providers.dart';
import 'package:ethiopian_food_app/features/auth/widgets/auth_shell.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLogin = true;
  bool _isSubmitting = false;
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSubmitting = true);
    final authService = ref.read(authServiceProvider);

    try {
      if (_isLogin) {
        await authService.login(_emailController.text.trim(), _passwordController.text);
      } else {
        await authService.register(
          _fullNameController.text.trim(),
          _emailController.text.trim(),
          _passwordController.text,
        );
      }
      if (!mounted) return;
      context.go('/dashboard');
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
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
                    ? 'Please enter your name'
                    : null,
              ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) return 'Enter your email';
                if (!value.contains('@')) return 'Enter a valid email';
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
                if (value == null || value.isEmpty) return 'Enter your password';
                if (!_isLogin && value.length < 8) return 'Password must be at least 8 characters';
                return null;
              },
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _isSubmitting ? null : _submit,
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.login_rounded),
              label: Text(_isLogin ? 'Sign in' : 'Create account'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => setState(() => _isLogin = !_isLogin),
              child: Text(_isLogin ? 'Need an account? Sign up' : 'Already have an account? Sign in'),
            ),
          ],
        ),
      ),
      footer: TextButton(
        onPressed: () => context.go('/dashboard'),
        child: const Text('Continue without signing in'),
      ),
    );
  }
}
