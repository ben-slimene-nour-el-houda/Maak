import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/providers/language_provider.dart';
import 'language_selection_screen.dart';

class TunisiaConnectScreen extends StatelessWidget {
  const TunisiaConnectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A2A6E),
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),

                // ==================== YOUR REAL LOGO ====================
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    image: DecorationImage(
                      image: AssetImage('assets/images/logo2.jpeg'),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                // ======================================================

                const SizedBox(height: 12),

                // Arabic Subtitle
                Text(
                  'إدارتك الرقمية الذكية',
                  style: GoogleFonts.cairo(
                    fontSize: 19,
                    fontWeight: FontWeight.w500,
                    color: Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 8),

                // English Subtitle
                Text(
                  'Your smart administrative assistant',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.white60,
                  ),
                  textAlign: TextAlign.center,
                ),

                const Spacer(flex: 3),

                // Get Started Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const LanguageSelectionScreen(),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white, width: 1.8),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Get Started',
                      style: TextStyle(
                        fontSize: 17.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 50),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
