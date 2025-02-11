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
import 'services/location_service.dart';
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebViewScreen extends StatelessWidget {
  final String url;

  const WebViewScreen({super.key, required this.url});

  @override
  Widget build(BuildContext context) {
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(url));

    return Scaffold(
      body: Stack(
        children: [
          WebViewWidget(controller: controller),
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => const MyApp()),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> preloadCache() async {
  final prefs = await SharedPreferences.getInstance();
  if (!prefs.containsKey("preloaded")) {
    await MovieService.fetchAllByType("movie");
    await MovieService.fetchAllByType("tv_show");
    prefs.setBool("preloaded", true);
  }
}

Future<void> main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();

    // Initialize Firebase with error handling
    try {
      await Firebase.initializeApp();
    } catch (e) {
      print('Failed to initialize Firebase: $e');
    }

    // Initialize notifications with error handling
    try {
      await NotificationService.instance.init();
    } catch (e) {
      print('Failed to initialize notifications: $e');
    }

    // Initialize remote config
    final remoteConfig = FirebaseRemoteConfig.instance;
    await remoteConfig.setConfigSettings(RemoteConfigSettings(
      fetchTimeout: const Duration(minutes: 1),
      minimumFetchInterval: const Duration(seconds: 30),
    ));
    await remoteConfig.fetchAndActivate();

    // Get country from location service
    try {
      final country = await LocationService.initializeLocation();
      if (country != null) {
        print('Country detected: $country');
        
        // Get and parse the country configuration from remote config
        final countryConfigStr = remoteConfig.getString('moviemagicbox_countries');
        print('Remote config country string: $countryConfigStr');
        
        if (countryConfigStr.isNotEmpty) {
          try {
            final List<dynamic> countryConfigList = json.decode(countryConfigStr);
            if (countryConfigList.isNotEmpty) {
              final countryConfig = countryConfigList[0];
              final upperCountry = country.toUpperCase();
              print('Checking country: $upperCountry against config: $countryConfig');
              
              if (countryConfig is Map && countryConfig.containsKey(upperCountry)) {
                final url = countryConfig[upperCountry];
                print('URL found for country $upperCountry: $url');
                
                if (url != null && url.toString().isNotEmpty) {
                  print('Loading WebView with URL: $url');
                  runApp(MaterialApp(
                    home: WebViewScreen(url: url.toString()),
                    debugShowCheckedModeBanner: false,
                  ));
                  return;
                }
              } else {
                print('Country $upperCountry not found in config or invalid config format');
              }
            }
          } catch (e) {
            print('Error parsing country config: $e');
          }
        } else {
          print('Empty country config string from remote config');
        }
      } else {
        print('Could not determine country');
      }
    } catch (e) {
      print('Failed to initialize location: $e');
    }

    // Request tracking authorization with error handling
    try {
      final status = await AppTrackingTransparency.trackingAuthorizationStatus;
      if (status == TrackingStatus.notDetermined) {
        await Future.delayed(const Duration(seconds: 1));
        final newStatus = await AppTrackingTransparency.requestTrackingAuthorization();
        if (newStatus == TrackingStatus.authorized) {
          final devKey = await fetchDevKeyFromRemoteConfig().catchError((e) {
            print('Error fetching dev key: $e');
            return 'TVuiYiPd4Bu5wzUuZwTymX';
          });
          initAppsFlyer(devKey, true);
        }
      } else if (status == TrackingStatus.authorized) {
        final devKey = await fetchDevKeyFromRemoteConfig().catchError((e) {
          print('Error fetching dev key: $e');
          return 'TVuiYiPd4Bu5wzUuZwTymX';
        });
        initAppsFlyer(devKey, true);
      }
    } catch (e) {
      print('Failed to initialize tracking: $e');
    }

    // Preload cache with error handling
    try {
      await preloadCache();
    } catch (e) {
      print('Failed to preload cache: $e');
    }

    // Run app
    runApp(const MyApp());
  } catch (e) {
    print('Fatal error during initialization: $e');
    runApp(const MyApp());
  }
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
