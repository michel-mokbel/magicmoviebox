import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:moviemagicbox/screens/welcome_screen.dart';
import 'package:moviemagicbox/services/movie_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:appsflyer_sdk/appsflyer_sdk.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';

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
  RequestConfiguration configuration = RequestConfiguration(
    testDeviceIds: ['00008030-0004481C1185402E'],
  );
  MobileAds.instance.updateRequestConfiguration(configuration);
  await Firebase.initializeApp();
  // Fetch dev_key from Firebase Remote Config
  String devKey = await fetchDevKeyFromRemoteConfig();
  initAppsFlyer(devKey);

  await preloadCache();
  runApp(const MyApp());
}

Future<String> fetchDevKeyFromRemoteConfig() async {
  final FirebaseRemoteConfig remoteConfig = FirebaseRemoteConfig.instance;

  try {
    // Set default values (optional)
    await remoteConfig.setDefaults(<String, dynamic>{
      'dev_key': 'TVuiYiPd4Bu5wzUuZwTymX', // Default value if the key isn't available
    });

    // Fetch and activate the remote config values
    await remoteConfig.fetchAndActivate();

    // Get the dev_key value
    String devKey = remoteConfig.getString('dev_key');
    print('Fetched dev_key: $devKey');

    return devKey;
  } catch (e) {
    print('Error fetching dev_key from Remote Config: $e');
    return 'TVuiYiPd4Bu5wzUuZwTymX'; // Fallback to default value in case of an error
  }
}

void initAppsFlyer(String devKey) {
  // SDK Options
  final AppsFlyerOptions options = AppsFlyerOptions(
      // afDevKey: "TVuiYiPd4Bu5wzUuZwTymX",
      afDevKey: devKey,
      appId: "6741157554",
      showDebug: true,
      timeToWaitForATTUserAuthorization: 15,
      manualStart: false);

  final appsflyerSdk = AppsflyerSdk(options);

  // Initialization of the AppsFlyer SDK
  appsflyerSdk.initSdk(
      registerConversionDataCallback: true,
      registerOnAppOpenAttributionCallback: true,
      registerOnDeepLinkingCallback: true);

  // Starting the SDK with optional success and error callbacks
  appsflyerSdk.startSDK(
    onSuccess: () {
      print("AppsFlyer SDK initialized successfully.");
    },
    onError: (int errorCode, String errorMessage) {
      print(
          "Error initializing AppsFlyer SDK: Code $errorCode - $errorMessage");
    },
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();

  // Static method to change the locale from anywhere in the app.
  static void setLocale(BuildContext context, Locale newLocale) {
    // Find the nearest _MyAppState in the widget tree
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
