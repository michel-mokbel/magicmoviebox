import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:moviemagicbox/screens/welcome_screen.dart';
import 'package:moviemagicbox/services/movie_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:appsflyer_sdk/appsflyer_sdk.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'services/notification_service.dart';

Future<void> preloadCache() async {
  final prefs = await SharedPreferences.getInstance();
  if (!prefs.containsKey("preloaded")) {
    await MovieService.fetchAllByType("movie");
    await MovieService.fetchAllByType("tv_show");
    prefs.setBool("preloaded", true);
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configure test device for ads
  // RequestConfiguration configuration = RequestConfiguration(
  //   testDeviceIds: ['00008030-0004481C1185402E'],
  // );
  // MobileAds.instance.updateRequestConfiguration(configuration);

  await Firebase.initializeApp();

  // Request App Tracking Transparency permission
  TrackingStatus status = await AppTrackingTransparency.requestTrackingAuthorization();
  bool isTrackingAllowed = status == TrackingStatus.authorized;

  if (isTrackingAllowed) {
    // Fetch AppsFlyer dev_key from Firebase Remote Config
    String devKey = await fetchDevKeyFromRemoteConfig();
    initAppsFlyer(devKey, isTrackingAllowed);
  }

  await preloadCache();
  await NotificationService.instance.init();
  runApp(const MyApp());
}

Future<String> fetchDevKeyFromRemoteConfig() async {
  final FirebaseRemoteConfig remoteConfig = FirebaseRemoteConfig.instance;
  try {
    await remoteConfig.setDefaults(<String, dynamic>{
      'dev_key': 'TVuiYiPd4Bu5wzUuZwTymX', // Default value if Remote Config fails
    });
    await remoteConfig.fetchAndActivate();
    String devKey = remoteConfig.getString('dev_key');
    print('Fetched dev_key: $devKey');
    return devKey;
  } catch (e) {
    print('Error fetching dev_key from Remote Config: $e');
    return 'TVuiYiPd4Bu5wzUuZwTymX'; // Fallback dev key
  }
}

void initAppsFlyer(String devKey, bool isTrackingAllowed) {
  // Set timeToWaitForATTUserAuthorization based on tracking permission
  final double timeToWait = isTrackingAllowed ? 10 : 0;

  final AppsFlyerOptions options = AppsFlyerOptions(
      afDevKey: devKey,
      appId: "6741157554",
      showDebug: true,
      timeToWaitForATTUserAuthorization: timeToWait, // Set based on permission
      manualStart: false);

  final appsflyerSdk = AppsflyerSdk(options);

  if (isTrackingAllowed) {
    // Initialize AppsFlyer SDK ONLY if tracking is allowed
    appsflyerSdk.initSdk(
        registerConversionDataCallback: true,
        registerOnAppOpenAttributionCallback: true,
        registerOnDeepLinkingCallback: true);
    appsflyerSdk.startSDK(
      onSuccess: () => print("AppsFlyer SDK initialized successfully."),
      onError: (int errorCode, String errorMessage) =>
          print("Error initializing AppsFlyer SDK: Code $errorCode - $errorMessage"),
    );
  } else {
    print("Tracking denied, skipping AppsFlyer initialization.");
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();

  static void setLocale(BuildContext context, Locale newLocale) {
    final _MyAppState? state = context.findAncestorStateOfType<_MyAppState>();
    state?.setLocale(newLocale);
  }
}

class _MyAppState extends State<MyApp> {
  Locale? _locale;

  @override
  void initState() {
    super.initState();
  }

  void setLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: _locale ?? ui.window.locale,
      supportedLocales: const [
        Locale('en', ''),
        Locale('es', ''),
        Locale('fr', ''),
        Locale('ar', ''),
        Locale('pl', ''),
        Locale('bg', ''),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      localeResolutionCallback: (locale, supportedLocales) {
        for (var supportedLocale in supportedLocales) {
          if (supportedLocale.languageCode == locale?.languageCode) {
            return supportedLocale;
          }
        }
        return const Locale('en', '');
      },
      debugShowCheckedModeBanner: false,
      home: const WelcomeScreen(),
    );
  }
}
