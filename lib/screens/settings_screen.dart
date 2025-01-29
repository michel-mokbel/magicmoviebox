// ignore_for_file: library_private_types_in_public_api, avoid_print, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:moviemagicbox/assets/ads/native_ad.dart';
import 'package:moviemagicbox/main.dart';
import 'package:share_plus/share_plus.dart';


class Settings extends StatefulWidget {

  const Settings({super.key});
  @override
  _SettingsState createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  get http => null;


  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
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
    const String appUrl = 'https://apps.apple.com/app/id';
    Share.share(appUrl);
  }


  void showPrivacyPolicy(BuildContext context) async {
    // Get the current locale
    String htmlFilePath;

        htmlFilePath = 'lib/assets/html/privacy_policy_en.html';
    

    // Load the corresponding HTML file content
    String htmlData = await rootBundle.loadString(htmlFilePath);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Privacy Policy'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Html(data: htmlData),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  // Show language selection dialog
  void showLanguageSelectionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Languages'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('English'),
                onTap: () {
                  MyApp.setLocale(context, const Locale('en', ''));
                  Navigator.of(context).pop();
                },
              ),

              // ListTile(
              //   title: const Text('Español'),
              //   onTap: () {
              //     MyApp.setLocale(context, const Locale('es', ''));
              //     Navigator.of(context).pop();
              //   },
              // ),
              // ListTile(
              //   title: const Text('العربية'),
              //   onTap: () {
              //     MyApp.setLocale(context, const Locale('ar', ''));
              //     Navigator.of(context).pop();
              //   },
              // ),
              // ListTile(
              //   title: const Text('Polski'),
              //   onTap: () {
              //     MyApp.setLocale(context, const Locale('pl', ''));
              //     Navigator.of(context).pop();
              //   },
              // ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      bottom: false,
      child: Scaffold(
        backgroundColor:  Colors.black,
        body: Container(
          margin: const EdgeInsets.all(8.0),
          child: SizedBox.expand(
            child: Center(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 100),
                  // Profile Section
                  const Center(
                    child: Column(
                      children: [
                        // _bannerAdManager.getBannerAdWidget(),
                        SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundImage: AssetImage(
                                  'lib/assets/images/profile-pic.png'),
                            ),
                          ],
                        ),
                        SizedBox(height: 10),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  Column(
                    children: [
                      buildSettingsOption(
                        context,
                        icon: Icons.language,
                        title: 'Language',
                        onTap: () {
                          showLanguageSelectionDialog(context);
                        },
                      ),
                      const Divider(),
                      buildSettingsOption(
                        context,
                        icon: Icons.share,
                        title: 'Share App',
                        onTap: () {
                          shareApp(context);
                        },
                      ),
                      const Divider(),
                      buildSettingsOption(
                        context,
                        icon: Icons.privacy_tip,
                        title: 'Privacy Policy',
                        onTap: () {
                          showPrivacyPolicy(context);
                        },
                      ),
                      // const NativeAdWidget(),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
