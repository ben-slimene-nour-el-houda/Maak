import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/providers/language_provider.dart';
import '../core/constants/app_strings.dart';
import 'profile_creation_screen.dart';
import 'home_screen.dart';

class LanguageSelectionScreen extends StatelessWidget {
  const LanguageSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final langProvider = Provider.of<LanguageProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.get(context, 'step_1_of_3')),
        centerTitle: false,
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.get(context, 'choose_language'),
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),

            _buildLanguageTile(
                context, '🇹🇳', 'العربية', 'Arabic', AppLanguage.arabic, langProvider),
            const SizedBox(height: 12),
            _buildLanguageTile(
                context, '🇫🇷', 'Français', 'French', AppLanguage.french, langProvider),
            const SizedBox(height: 12),
            _buildLanguageTile(
                context, '🗣️', 'Darija', 'Tunisian Arabic dialect', AppLanguage.darija, langProvider),

            const Spacer(),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F8FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.mic, color: Colors.blue),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text('Voice Input Available\nAll languages support voice commands'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  final hasAccount = prefs.getBool('hasAccount') ?? false;

                  if (hasAccount) {
                    // User already has an account → go directly to home/dashboard
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const HomeScreen()),
                    );
                  } else {
                    // New user → go to profile creation
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const ProfileCreationScreen()),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0A2A6E),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  AppStrings.get(context, 'next'),
                  style: const TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageTile(
      BuildContext context,
      String flag,
      String title,
      String subtitle,
      AppLanguage lang,
      LanguageProvider provider) {
    final isSelected = provider.currentLanguage == lang;

    return GestureDetector(
      onTap: () => provider.changeLanguage(lang),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? const Color(0xFF0A2A6E) : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          leading: Text(flag, style: const TextStyle(fontSize: 28)),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(subtitle),
          trailing: isSelected ? const Icon(Icons.check_circle, color: Color(0xFF0A2A6E)) : null,
        ),
      ),
    );
  }
}