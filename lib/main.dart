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
import 'package:app_set_id/app_set_id.dart';
import 'dart:convert';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:uuid/uuid.dart';

class WebViewScreen extends StatelessWidget {
  final String url;

  const WebViewScreen({super.key, required this.url});

  @override
  Widget build(BuildContext context) {
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            print('Page started loading: $url');
          },
          onPageFinished: (String url) {
            print('Page finished loading: $url');
          },
          onWebResourceError: (WebResourceError error) {
            print('WebView error: ${error.description}');
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const WelcomeScreen()),
            );
          },
          onNavigationRequest: (NavigationRequest request) {
            print('Navigation request to: ${request.url}');

            // Check if the URL starts with error://
            if (request.url.startsWith('error://')) {
              print('Error scheme detected, redirecting to welcome screen');
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const WelcomeScreen()),
              );
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(url));

    return Scaffold(
      body: Stack(
        children: [
          SafeArea(child: WebViewWidget(controller: controller)),
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

Future<String> getOrCreateUUID() async {
  final prefs = await SharedPreferences.getInstance();
  String? uuid = prefs.getString('device_uuid');

  if (uuid == null) {
    uuid = const Uuid().v4();
    await prefs.setString('device_uuid', uuid);
  }

  return uuid;
}

Future<String?> getAppsFlyerId() async {
  try {
    final devKey = await fetchDevKeyFromRemoteConfig().catchError((e) {
      print('Error fetching dev key: $e');
      return 'TVuiYiPd4Bu5wzUuZwTymX';
    });
    
    final appsflyerSdk = initAppsFlyerInstance(devKey);
    final result = await appsflyerSdk.getAppsFlyerUID();
    return result;
  } catch (e) {
    print('Error getting AppsFlyer ID: $e');
    return null;
  }
}

Future<Map<String, String>> getDeviceInfo() async {
  final deviceInfo = <String, String>{};

  // Get or create persistent UUID
  final uuid = await getOrCreateUUID();
  deviceInfo['uuid'] = uuid;

  // Get IDFA (Advertising Identifier)
  try {
    final status = await AppTrackingTransparency.trackingAuthorizationStatus;
    if (status == TrackingStatus.authorized) {
      final idfa = await AppTrackingTransparency.getAdvertisingIdentifier();
      deviceInfo['idfa'] = idfa;
    } else {
      print('Tracking not authorized, status: $status');
      deviceInfo['idfa'] = '';
    }
  } catch (e) {
    print('Error getting IDFA: $e');
    deviceInfo['idfa'] = '';
  }

  // Get IDFV (Vendor Identifier)
  try {
    final appSetId = AppSetId();
    final idfv = await appSetId.getIdentifier();
    deviceInfo['idfv'] = idfv ?? '';
  } catch (e) {
    print('Error getting IDFV: $e');
    deviceInfo['idfv'] = '';
  }

  deviceInfo['bundle_id'] = 'com.appadsrocket.moviemagicbox';

  // Get AppsFlyer ID
  final appsFlyerId = await getAppsFlyerId();
  deviceInfo['appsflyer_id'] = appsFlyerId ?? '';

  print('Device info collected: $deviceInfo');
  return deviceInfo;
}

Future<void> main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();

    // Initialize Firebase
    try {
      await Firebase.initializeApp();
      print('Firebase initialized successfully');
    } catch (e) {
      print('Failed to initialize Firebase: $e');
    }

    // Initialize remote config
    final remoteConfig = FirebaseRemoteConfig.instance;
    await remoteConfig.setConfigSettings(RemoteConfigSettings(
      fetchTimeout: const Duration(minutes: 1),
      minimumFetchInterval: const Duration(minutes: 1),
    ));
    await remoteConfig.fetchAndActivate();

    // Get URL and show_att from remote config
    final url = remoteConfig.getValue('url');
    final showAtt = remoteConfig.getBool('show_att');

    print('Remote config URL: ${url.asString()}');
    print('Remote config show_att: $showAtt');
    print('Remote config source: ${url.source}');
    print('Remote config last fetch status: ${remoteConfig.lastFetchStatus}');
    print('Remote config last fetch time: ${remoteConfig.lastFetchTime}');

    // Initialize AppsFlyer early, but don't start tracking yet
    final devKey = await fetchDevKeyFromRemoteConfig().catchError((e) {
      print('Error fetching dev key: $e');
      return 'TVuiYiPd4Bu5wzUuZwTymX';
    });
    
    // Create AppsFlyer instance early - will be started after ATT check
    final appsflyerSdk = initAppsFlyerInstance(devKey);

    if (url.asString().isNotEmpty) {
      // If URL is present, request ATT in splash screen
      try {
        if (showAtt) {
          await Future.delayed(const Duration(seconds: 1));
          final status =
              await AppTrackingTransparency.requestTrackingAuthorization();
          print('Tracking authorization status: $status');
          
          // Start AppsFlyer SDK with appropriate settings based on permission
          startAppsFlyerTracking(appsflyerSdk, status == TrackingStatus.authorized);
        } else {
          // If show_att is false, start AppsFlyer without full tracking
          startAppsFlyerTracking(appsflyerSdk, false);
        }
      } catch (e) {
        print('Failed to request tracking authorization: $e');
        // Start AppsFlyer even on error, but without full tracking
        startAppsFlyerTracking(appsflyerSdk, false);
      }

      // Get device information
      final deviceInfo = await getDeviceInfo();

      // Replace placeholders in URL
      var finalUrl = url
          .asString()
          .replaceAll('{bundle_id}', deviceInfo['bundle_id']!)
          .replaceAll('{uuid}', deviceInfo['uuid']!)
          .replaceAll('{idfa}', deviceInfo['idfa']!)
          .replaceAll('{idfv}', deviceInfo['idfv']!)
          .replaceAll('{appsflyer_id}', deviceInfo['appsflyer_id']!);

      print('Final URL with parameters: $finalUrl');

      // Launch WebView with the URL
      runApp(MaterialApp(
        home: WebViewScreen(url: finalUrl),
        debugShowCheckedModeBanner: false,
      ));
      return;
    } else {
      // Start AppsFlyer for main app flow as well
      // Request ATT if needed
      if (showAtt) {
        try {
          final status =
              await AppTrackingTransparency.requestTrackingAuthorization();
          startAppsFlyerTracking(appsflyerSdk, status == TrackingStatus.authorized);
        } catch (e) {
          print('Failed to request tracking authorization: $e');
          startAppsFlyerTracking(appsflyerSdk, false);
        }
      } else {
        // Start without full tracking if show_att is false
        startAppsFlyerTracking(appsflyerSdk, false);
      }
    }

    // Preload cache
    try {
      await preloadCache();
    } catch (e) {
      print('Failed to preload cache: $e');
    }

    // Run normal app if WebView conditions not met
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
      'dev_key':
          'TVuiYiPd4Bu5wzUuZwTymX', // Default value if Remote Config fails
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


// Modified to create instance but not start tracking
AppsflyerSdk initAppsFlyerInstance(String devKey) {
  final AppsFlyerOptions options = AppsFlyerOptions(
      afDevKey: devKey,
      appId: "6741157554",
      showDebug: true,
      timeToWaitForATTUserAuthorization: 0, // Give time for ATT dialog
      manualStart: true); // Important: We'll manually start it later
      
  return AppsflyerSdk(options);
}

// New function to start tracking with appropriate settings
void startAppsFlyerTracking(AppsflyerSdk appsflyerSdk, bool isTrackingAllowed) {
  // Always initialize SDK with appropriate callbacks
  appsflyerSdk.initSdk(
      registerConversionDataCallback: true,
      registerOnAppOpenAttributionCallback: true,
      registerOnDeepLinkingCallback: true);
  
  // Start SDK
  appsflyerSdk.startSDK(
    onSuccess: () {
      print("AppsFlyer SDK initialized successfully.");
      
      // Log app open event if tracking is allowed
      if (isTrackingAllowed) {
        appsflyerSdk.logEvent("app_open", {
          "first_open_time": DateTime.now().toIso8601String(),
        });
      }
    },
    onError: (int errorCode, String errorMessage) => 
        print("Error initializing AppsFlyer SDK: Code $errorCode - $errorMessage"),
  );
  
  // Log limited events even if tracking isn't fully allowed
  appsflyerSdk.logEvent("af_first_open", {});
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
