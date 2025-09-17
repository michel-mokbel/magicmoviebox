// Flutter web plugin registrant file.
//
// Generated file. Do not edit.
//

// @dart = 2.13
// ignore_for_file: type=lint

import 'package:app_set_id/app_set_id_web.dart';
import 'package:firebase_core_web/firebase_core_web.dart';
import 'package:firebase_remote_config_web/firebase_remote_config_web.dart';
import 'package:flutter_native_splash/flutter_native_splash_web.dart';
import 'package:geolocator_web/geolocator_web.dart';
import 'package:google_maps_flutter_web/google_maps_flutter_web.dart';
import 'package:share_plus/src/share_plus_web.dart';
import 'package:shared_preferences_web/shared_preferences_web.dart';
import 'package:url_launcher_web/url_launcher_web.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

void registerPlugins([final Registrar? pluginRegistrar]) {
  final Registrar registrar = pluginRegistrar ?? webPluginRegistrar;
  AppSetIdWeb.registerWith(registrar);
  FirebaseCoreWeb.registerWith(registrar);
  FirebaseRemoteConfigWeb.registerWith(registrar);
  FlutterNativeSplashWeb.registerWith(registrar);
  GeolocatorPlugin.registerWith(registrar);
  GoogleMapsPlugin.registerWith(registrar);
  SharePlusWebPlugin.registerWith(registrar);
  SharedPreferencesPlugin.registerWith(registrar);
  UrlLauncherPlugin.registerWith(registrar);
  registrar.registerMessageHandler();
}
