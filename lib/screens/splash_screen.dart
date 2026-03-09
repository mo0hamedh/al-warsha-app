import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/logo.png',
              width: 120,
              height: 120,
            ),
            const SizedBox(height: 16),
            Text(
              "الـ وَرشة",
              style: GoogleFonts.ibmPlexSansArabic(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "أنجز أكثر. ركز أعمق.",
              style: GoogleFonts.ibmPlexSansArabic(
                color: const Color(0xFF555555),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
