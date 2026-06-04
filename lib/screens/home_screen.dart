// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/providers/language_provider.dart';
import '../core/providers/accessibility_provider.dart';
import '../core/database/database_helper.dart';
import '../models/user_profile.dart';
import 'ai_form_screen.dart';
import 'procedure_assistant_screen.dart';
import 'office_finder_screen.dart';
import 'optimizer_screen.dart';
import 'accessibility_settings_screen.dart';
import '../core/constants/app_strings.dart';
import 'chatbot_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  UserProfile? _userProfile;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await DatabaseHelper.instance.getProfile();
    if (profile != null && mounted) {
      setState(() => _userProfile = profile);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final accessibility = Provider.of<AccessibilityProvider>(context);

    final double cardFontSize = accessibility.simpleMode ? 16 : 17;
    final double iconSize = accessibility.mobilityMode ? 42 : 48;

    return Directionality(
      textDirection: (lang.currentLanguage == AppLanguage.arabic ||
              lang.currentLanguage == AppLanguage.darija)
          ? TextDirection.rtl
          : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF1E3A8A),
          title: const Text(
            'Tunisia Connect',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.history),
              onPressed: () {
                // TODO: History Screen
              },
            ),
            IconButton(
              icon: const Icon(Icons.person_outline),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const AccessibilitySettingsScreen()),
                );
              },
            ),
          ],
        ),

        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 👋 Optional greeting
              if (_userProfile != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    '👋 Bonjour ${_userProfile!.fullName}',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ),

              // 🔔 Notification Banner
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E40AF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.notifications, color: Colors.white),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.get(context, 'notification_title'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            AppStrings.get(context, 'notification_subtitle'),
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 🔍 Search Bar
              TextField(
                decoration: InputDecoration(
                  hintText: AppStrings.get(context, 'search_hint'),
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // ⚡ Quick Actions
              Text(
                AppStrings.get(context, 'quick_actions'),
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 16),

              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.05,
                children: [
                  _buildQuickActionCard(
                    icon: Icons.description_outlined,
                    title: AppStrings.get(context, 'ai_form'),
                    subtitle: AppStrings.get(context, 'ai_form_desc'),
                    color: Colors.blue,
                    iconSize: iconSize,
                    fontSize: cardFontSize,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const AiFormScreen()),
                    ),
                  ),
                  _buildQuickActionCard(
                    icon: Icons.explore_outlined,
                    title: AppStrings.get(context, 'procedures'),
                    subtitle: AppStrings.get(context, 'procedures_desc'),
                    color: Colors.orange,
                    iconSize: iconSize,
                    fontSize: cardFontSize,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              const ProcedureAssistantScreen()),
                    ),
                  ),
                  _buildQuickActionCard(
                    icon: Icons.location_on_outlined,
                    title: AppStrings.get(context, 'office_finder'),
                    subtitle:
                        AppStrings.get(context, 'office_finder_desc'),
                    color: Colors.green,
                    iconSize: iconSize,
                    fontSize: cardFontSize,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              const OfficeFinderScreen()),
                    ),
                  ),
                  _buildQuickActionCard(
                    icon: Icons.access_time,
                    title: AppStrings.get(context, 'visit_optimizer'),
                    subtitle:
                        AppStrings.get(context, 'visit_optimizer_desc'),
                    color: Colors.purple,
                    iconSize: iconSize,
                    fontSize: cardFontSize,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              const OptimizerScreen()),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // 🕓 Recent Activity
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppStrings.get(context, 'recent_activity'),
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: Text(AppStrings.get(context, 'see_all')),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              _buildRecentActivityItem(
                title: AppStrings.get(context, 'activity_1'),
                time: AppStrings.get(context, 'activity_1_time'),
                status: AppStrings.get(context, 'saved'),
                statusColor: Colors.green,
              ),
              const SizedBox(height: 12),
              _buildRecentActivityItem(
                title: AppStrings.get(context, 'activity_2'),
                time: AppStrings.get(context, 'activity_2_time'),
                status: AppStrings.get(context, 'offline'),
                statusColor: Colors.orange,
              ),
            ],
          ),
        ),

        // 🔻 Bottom Navigation
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          selectedItemColor: const Color(0xFF1E40AF),
          unselectedItemColor: Colors.grey,
          onTap: (index) {
            setState(() => _currentIndex = index);

            if (index == 1) {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const AiFormScreen()),
              );
            } else if (index == 2) {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const OfficeFinderScreen()),
              );
            } else if (index == 3) {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        const AccessibilitySettingsScreen()),
              );
            }
          },
          items: [
            BottomNavigationBarItem(
                icon: const Icon(Icons.home),
                label: AppStrings.get(context, 'home')),
            BottomNavigationBarItem(
                icon: const Icon(Icons.assistant),
                label: AppStrings.get(context, 'assistant')),
            BottomNavigationBarItem(
                icon: const Icon(Icons.location_on),
                label: AppStrings.get(context, 'offices')),
            BottomNavigationBarItem(
                icon: const Icon(Icons.person),
                label: AppStrings.get(context, 'profile')),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ChatbotScreen()),
            );
          },
          backgroundColor: const Color(0xFF1D9E75),
          elevation: 4,
          child: const Icon(Icons.support_agent, color: Colors.white, size: 28),
        ),
      ),
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required double iconSize,
    required double fontSize,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.08),
              blurRadius: 8,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: iconSize, color: color),
            const SizedBox(height: 12),
            Text(title,
                style: TextStyle(
                    fontSize: fontSize, fontWeight: FontWeight.w600)),
            Text(subtitle,
                style:
                    const TextStyle(fontSize: 13, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivityItem({
    required String title,
    required String time,
    required String status,
    required Color statusColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.description_outlined, color: Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style:
                        const TextStyle(fontWeight: FontWeight.w500)),
                Text(time,
                    style: const TextStyle(
                        color: Colors.grey, fontSize: 13)),
              ],
            ),
          ),
          Text(
            status,
            style: TextStyle(
                color: statusColor, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}