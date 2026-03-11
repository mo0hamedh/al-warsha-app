import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../../../providers/theme_provider.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthService>();
    final error = await auth.resetPassword(_emailController.text.trim());

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error ?? 'تم إرسال رابط استعادة كلمة المرور إلى بريدك الإلكتروني',
            style: GoogleFonts.tajawal(),
          ),
          backgroundColor: error == null ? Colors.green : Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );

      if (error == null) {
        Navigator.pop(context); // Go back to login screen on success
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
        title: Text('إستعادة كلمة المرور', style: GoogleFonts.tajawal(color: theme.primaryText, fontWeight: FontWeight.bold)),
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
                    Icon(
                      Icons.lock_reset,
                      size: 80,
                      color: theme.accentColor,
                      shadows: [Shadow(color: theme.accentColor.withOpacity(0.5), blurRadius: 15)],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'نسيت كلمة المرور؟',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.tajawal(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: theme.primaryText,
                        shadows: [Shadow(color: theme.primaryText.withOpacity(0.3), blurRadius: 6)],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'أدخل بريدك الإلكتروني وسنرسل لك رابطاً لتعيين كلمة مرور جديدة',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.tajawal(fontSize: 16, color: theme.textSecondary),
                    ),
                    const SizedBox(height: 48),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: GoogleFonts.tajawal(color: theme.primaryText),
                      decoration: InputDecoration(
                        labelText: 'البريد الإلكتروني',
                        labelStyle: GoogleFonts.tajawal(color: theme.textSecondary),
                        prefixIcon: Icon(Icons.email_outlined, color: theme.textSecondary),
                        filled: true,
                        fillColor: theme.card,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: theme.accentColor, width: 1.5)),
                      ),
                      validator: (val) => val != null && val.contains('@') ? null : 'يرجى إدخال بريد إلكتروني صحيح',
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: auth.isLoading ? null : _resetPassword,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        backgroundColor: theme.accentColor,
                        foregroundColor: Colors.white,
                        elevation: 8,
                        shadowColor: theme.accentColor.withOpacity(0.5),
                      ),
                      child: auth.isLoading
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text('إرسال الرابط', style: GoogleFonts.tajawal(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('العودة لتسجيل الدخول', style: GoogleFonts.tajawal(color: theme.accentColor)),
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
