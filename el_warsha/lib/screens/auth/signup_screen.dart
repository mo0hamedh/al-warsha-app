import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/auth_service.dart';
import '../../providers/theme_provider.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthService>();
    final error = await auth.signUp(
      name: _nameController.text.trim(),
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

  Future<void> _signUpWithGoogle() async {
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
      appBar: AppBar(
        title: Text('إنشاء حساب', style: GoogleFonts.cairo(color: theme.primaryText, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: theme.primaryText),
        centerTitle: true,
      ),
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
                    Text(
                      'ابدأ رحلتك!',
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
                      'قم بإنشاء حساب لتنظيم مهامك بكفاءة',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.cairo(fontSize: 16, color: theme.textSecondary),
                    ),
                    const SizedBox(height: 48),
                    TextFormField(
                      controller: _nameController,
                      style: GoogleFonts.cairo(color: theme.primaryText),
                      decoration: InputDecoration(
                        labelText: 'الاسم الكامل',
                        labelStyle: GoogleFonts.cairo(color: theme.textSecondary),
                        prefixIcon: Icon(Icons.person_outline, color: theme.textSecondary),
                        filled: true,
                        fillColor: theme.card,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: theme.accentOrange, width: 1.5)),
                      ),
                      validator: (val) => val != null && val.isNotEmpty ? null : 'يرجى إدخال اسمك',
                    ),
                    const SizedBox(height: 16),
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
                      validator: (val) => val != null && val.length > 5 ? null : 'يجب أن لا تقل كلمة المرور عن 6 أحرف',
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: auth.isLoading ? null : _signUp,
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
                          : Text('إنشاء حساب', style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: auth.isLoading ? null : _signUpWithGoogle,
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
                      onPressed: () => context.go('/login'),
                      child: Text('لديك حساب بالفعل؟ تسجيل الدخول', style: GoogleFonts.cairo(color: theme.accentOrange)),
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
