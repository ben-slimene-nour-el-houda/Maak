import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/providers/language_provider.dart';
import 'language_selection_screen.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);

    Future.delayed(const Duration(seconds: 2), () {
      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LanguageSelectionScreen()),
        );
      }
    });

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.account_balance, size: 120, color: Color(0xFF1E88E5)),
            const SizedBox(height: 20),
            Text(
              lang.t('app_name'),
              style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
            ),
            Text(
              lang.t('splash_subtitle'),
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}