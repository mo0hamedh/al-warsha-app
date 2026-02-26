import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/auth_service.dart';
import '../../providers/theme_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthService>();
    final error = await auth.login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (error != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error, style: GoogleFonts.cairo()),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else {
      if (mounted) {
        context.go('/home');
      }
    }
  }

  Future<void> _loginWithGoogle() async {
    final auth = context.read<AuthService>();
    final error = await auth.signInWithGoogle();

    if (error != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error, style: GoogleFonts.cairo()),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else {
      if (mounted) {
        context.go('/home');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final theme = context.watch<ThemeProvider>();

    return Scaffold(
      backgroundColor: theme.bg,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Form(
              key: _formKey,
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 80,
                      color: theme.primaryText,
                      shadows: [Shadow(color: theme.primaryText.withOpacity(0.5), blurRadius: 15)],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'مرحباً بعودتك!',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.cairo(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: theme.primaryText,
                        shadows: [Shadow(color: theme.primaryText.withOpacity(0.3), blurRadius: 6)],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'قم بتسجيل الدخول لمتابعة مهامك',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.cairo(fontSize: 16, color: theme.textSecondary),
                    ),
                    const SizedBox(height: 48),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: GoogleFonts.tajawal(color: theme.primaryText),
                      decoration: InputDecoration(
                        labelText: 'البريد الإلكتروني',
                        labelStyle: GoogleFonts.cairo(color: theme.textSecondary),
                        prefixIcon: Icon(Icons.email_outlined, color: theme.textSecondary),
                        filled: true,
                        fillColor: theme.card,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: theme.accentOrange, width: 1.5)),
                      ),
                      validator: (val) => val != null && val.contains('@') ? null : 'يرجى إدخال بريد إلكتروني صحيح',
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      style: GoogleFonts.tajawal(color: theme.primaryText),
                      decoration: InputDecoration(
                        labelText: 'كلمة المرور',
                        labelStyle: GoogleFonts.cairo(color: theme.textSecondary),
                        prefixIcon: Icon(Icons.lock_outline, color: theme.textSecondary),
                        filled: true,
                        fillColor: theme.card,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: theme.accentOrange, width: 1.5)),
                      ),
                      validator: (val) => val != null && val.length > 5 ? null : 'كلمة المرور ضعيفة جداً',
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: () => context.go('/forgot-password'),
                        child: Text('نسيت كلمة المرور؟', style: GoogleFonts.cairo(color: theme.textSecondary, fontSize: 13)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: auth.isLoading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        backgroundColor: theme.accentOrange,
                        foregroundColor: Colors.white,
                        elevation: 8,
                        shadowColor: theme.accentOrange.withOpacity(0.5),
                      ),
                      child: auth.isLoading
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text('دخول', style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: auth.isLoading ? null : _loginWithGoogle,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        side: BorderSide(color: theme.isDarkMode ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.1)),
                        foregroundColor: theme.primaryText,
                      ),
                      icon: const Icon(Icons.login),
                      label: Text('المتابعة بحساب جوجل', style: GoogleFonts.cairo(fontSize: 16)),
                    ),
                    const SizedBox(height: 24),
                    TextButton(
                      onPressed: () => context.go('/signup'),
                      child: Text('ليس لديك حساب؟ إنشاء حساب جديد', style: GoogleFonts.cairo(color: theme.accentOrange)),
                    ),
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
