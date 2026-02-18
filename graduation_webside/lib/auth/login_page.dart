import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Email / password login and registration screen using Supabase auth.
/// AstroBot AI Assistant style: dark tech background, centered form.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isRegister = false;
  bool _obscurePassword = true;

  final _formKey = GlobalKey<FormState>();

  SupabaseClient get _client => Supabase.instance.client;

  Future<void> _showError(String message) async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      if (_isRegister) {
        final res = await _client.auth.signUp(
          email: email,
          password: password,
        );
        if (res.user != null) {
          try {
            await _client.from('profiles').insert({
              'id': res.user!.id,
              'email': email,
            });
          } catch (_) {}
        } else {
          await _showError('Check your email to confirm your account.');
        }
      } else {
        await _client.auth.signInWithPassword(
          email: email,
          password: password,
        );
      }
    } on AuthException catch (e) {
      await _showError(e.message);
    } catch (e) {
      await _showError('Unexpected error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  static const Color _darkBg = Color(0xFF0A0E21);
  static const Color _accentBlue = Color(0xFF2196F3);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Dark blue background
          Container(color: _darkBg),
          // Circuit / network lines and dots
          CustomPaint(
            painter: _CircuitBackgroundPainter(),
            size: Size.infinite,
          ),
          // Centered content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Robot icon
                        const _RobotLogo(),
                        const SizedBox(height: 24),
                        // Title
                        Text(
                          _isRegister ? 'Sign Up' : 'Login',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _isRegister
                              ? 'Create your AstroBot account'
                              : 'Welcome to AstroBot AI Assistant',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                        const SizedBox(height: 40),
                        // Email
                        const Text(
                          'Email',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _emailController,
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Email is required';
                            if (!v.contains('@')) return 'Enter a valid email';
                            return null;
                          },
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(color: Colors.black87, fontSize: 15),
                          decoration: InputDecoration(
                            hintText: 'Enter your email address',
                            hintStyle: TextStyle(color: Colors.grey.shade600),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: _accentBlue,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Password
                        const Text(
                          'Password',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _passwordController,
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Password is required';
                            if (v.length < 6) return 'At least 6 characters';
                            return null;
                          },
                          obscureText: _obscurePassword,
                          style: const TextStyle(color: Colors.black87, fontSize: 15),
                          decoration: InputDecoration(
                            hintText: 'Enter your password',
                            hintStyle: TextStyle(color: Colors.grey.shade600),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: _accentBlue,
                                width: 2,
                              ),
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: Colors.grey.shade600,
                                size: 22,
                              ),
                              onPressed: () {
                                setState(() => _obscurePassword = !_obscurePassword);
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Forgot password (right-aligned when login)
                        if (!_isRegister)
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _isLoading
                                  ? null
                                  : () {
                                      // TODO: forgot password
                                    },
                              child: const Text(
                                'Forgot Password?',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        if (!_isRegister) const SizedBox(height: 8),
                        const SizedBox(height: 24),
                        // Login / Sign up button
                        SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _accentBlue,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    _isRegister ? 'Create account' : 'Login',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        // Don't have an account? Sign Up
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _isRegister
                                  ? 'Already have an account? '
                                  : 'Don\'t have an account? ',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 14,
                              ),
                            ),
                            TextButton(
                              onPressed: _isLoading
                                  ? null
                                  : () {
                                      setState(() => _isRegister = !_isRegister);
                                    },
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                _isRegister ? 'Log in' : 'Sign Up',
                                style: const TextStyle(
                                  color: _accentBlue,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
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
        ],
      ),
    );
  }
}

/// App logo: AstroBot robot image (image2.jpeg).
class _RobotLogo extends StatelessWidget {
  const _RobotLogo();

  static const Color _blue = Color(0xFF2196F3);
  static const String _logoAsset = 'image/asset/image/image2.jpeg';

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: _blue.withOpacity(0.5),
              blurRadius: 24,
              spreadRadius: 2,
            ),
          ],
        ),
        child: ClipOval(
          child: Image.asset(
            _logoAsset,
            fit: BoxFit.cover,
            width: 100,
            height: 100,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.smart_toy,
              size: 48,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

/// Paints circuit-board style lines and star-like dots on the background.
class _CircuitBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final blue = const Color(0xFF2196F3);
    final blueDim = blue.withOpacity(0.15);
    final blueGlow = blue.withOpacity(0.25);

    // Glowing lines from bottom and sides
    final linePaint = Paint()
      ..color = blueDim
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final glowPaint = Paint()
      ..color = blueGlow
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    final rnd = math.Random(42);
    for (int i = 0; i < 12; i++) {
      final start = Offset(
        rnd.nextDouble() * size.width,
        size.height + 20,
      );
      final end = Offset(
        rnd.nextDouble() * size.width,
        rnd.nextDouble() * size.height * 0.6,
      );
      canvas.drawLine(start, end, glowPaint);
      canvas.drawLine(start, end, linePaint);
    }

    for (int i = 0; i < 8; i++) {
      final start = Offset(-10, rnd.nextDouble() * size.height);
      final end = Offset(
        rnd.nextDouble() * size.width * 0.5,
        rnd.nextDouble() * size.height,
      );
      canvas.drawLine(start, end, glowPaint);
      canvas.drawLine(start, end, linePaint);
    }

    for (int i = 0; i < 8; i++) {
      final start = Offset(size.width + 10, rnd.nextDouble() * size.height);
      final end = Offset(
        size.width - rnd.nextDouble() * size.width * 0.5,
        rnd.nextDouble() * size.height,
      );
      canvas.drawLine(start, end, glowPaint);
      canvas.drawLine(start, end, linePaint);
    }

    // Star / data dots
    final dotPaint = Paint()..color = Colors.white.withOpacity(0.4);
    for (int i = 0; i < 80; i++) {
      final x = rnd.nextDouble() * size.width;
      final y = rnd.nextDouble() * size.height;
      final radius = 1.0 + rnd.nextDouble() * 1.5;
      canvas.drawCircle(Offset(x, y), radius, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
