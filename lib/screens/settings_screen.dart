// ignore_for_file: library_private_types_in_public_api, avoid_print, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:moviemagicbox/assets/ads/native_ad.dart';
import 'package:moviemagicbox/main.dart';
import 'package:share_plus/share_plus.dart';
import 'reminders_screen.dart';


class Settings extends StatefulWidget {

  const Settings({super.key});
  @override
  _SettingsState createState() => _SettingsState();
}

class _SettingsState extends State<Settings> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Widget buildSettingsOption(BuildContext context,
      {required IconData icon,
      required String title,
      required VoidCallback onTap,
      bool isDestructive = false}) {
    return ListTile(
      leading: Icon(icon, color: isDestructive ? Colors.red : Colors.red),
      title: Text(
        title,
        style: TextStyle(color: isDestructive ? Colors.red : Colors.red),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.white),
      onTap: onTap,
    );
  }

  void shareApp(BuildContext context) {
    const String appUrl = 'https://apps.apple.com/us/app/movie-magic-box/id6741157554';
    Share.share(appUrl);
  }


  void showPrivacyPolicy(BuildContext context) async {
    String htmlFilePath = 'lib/assets/html/privacy_policy_en.html';
    String htmlData = await rootBundle.loadString(htmlFilePath);

    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.red.withOpacity(0.8), const Color(0xFF8B0000)],
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Privacy Policy',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Html(
                  data: htmlData,
                  style: {
                    "body": Style(
                      color: Colors.white,
                      fontSize: FontSize(16),
                    ),
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Show language selection dialog
  void showLanguageSelectionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.red.withOpacity(0.8), const Color(0xFF8B0000)],
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: const Row(
                children: [
                  Text(
                    'Select Language',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  _buildLanguageOption(context, 'English', 'en'),

                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption(BuildContext context, String language, String code) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          MyApp.setLocale(context, Locale(code, ''));
          Navigator.pop(context);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                language,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.red.withOpacity(0.8), const Color(0xFF8B0000)],
                  ),
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(30),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Settings',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withOpacity(0.2),
                                Colors.white.withOpacity(0.1),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: const CircleAvatar(
                            radius: 40,
                            backgroundImage: AssetImage('lib/assets/images/profile-pic.png'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildSettingsTile(
                        icon: Icons.notifications,
                        title: 'Movie Reminders',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const RemindersScreen(),
                            ),
                          );
                        },
                      ),
                      _buildSettingsTile(
                        icon: Icons.language,
                        title: 'Language',
                        onTap: () => showLanguageSelectionDialog(context),
                      ),
                      _buildSettingsTile(
                        icon: Icons.share,
                        title: 'Share App',
                        onTap: () => shareApp(context),
                      ),
                      _buildSettingsTile(
                        icon: Icons.privacy_tip,
                        title: 'Privacy Policy',
                        onTap: () => showPrivacyPolicy(context),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDestructive
              ? [Colors.red.withOpacity(0.8), const Color(0xFF8B0000)]
              : [Colors.grey[900]!, Colors.grey[800]!],
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: (isDestructive ? Colors.red : Colors.black).withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(15),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                const Icon(
                  Icons.chevron_right,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
