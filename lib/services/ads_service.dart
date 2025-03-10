import 'package:flutter/material.dart';
import 'package:unity_ads_plugin/unity_ads_plugin.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

class AdsService {
  static final AdsService _instance = AdsService._internal();
  
  // Singleton pattern
  factory AdsService() => _instance;
  
  AdsService._internal() {
    print('DEBUG: AdsService instance created');
  }
  
  // Game ID from your Unity dashboard
  static const String gameId = "5808539";
  
  // Placement IDs
  static const String bannerPlacementId = "Banner_iOS";
  static const String interstitialPlacementId = "Rewarded_iOS";
  static const String rewardedPlacementId = "Rewarded_iOS";
  
  // Track initialization status
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;
  
  // Track if ads are enabled (user can disable via settings)
  bool _adsEnabled = true;
  bool get adsEnabled => _adsEnabled;
  
  // Interstitial cooldown to prevent showing too many ads
  DateTime? _lastInterstitialTime;
  static const int interstitialCooldownSeconds = 60; // Show max 1 interstitial per minute
  
  // Event bus for rewarded ad completion
  final StreamController<bool> _rewardStreamController = StreamController<bool>.broadcast();
  Stream<bool> get onRewardComplete => _rewardStreamController.stream;
  
  // Initialize the Unity Ads SDK
  Future<void> initialize() async {
    print('DEBUG: AdsService.initialize() called');
    if (_isInitialized) {
      print('DEBUG: Unity Ads already initialized, skipping');
      return;
    }
    
    try {
      // Load ad settings from preferences
      final prefs = await SharedPreferences.getInstance();
      _adsEnabled = prefs.getBool('ads_enabled') ?? true;
      print('DEBUG: Ads enabled? $_adsEnabled');
      
      print('DEBUG: Starting Unity Ads initialization with game ID: $gameId');
      
      // Create a completer to properly handle the async initialization
      final completer = Completer<void>();
      
      await UnityAds.init(
        gameId: gameId,
        testMode: false, // Set to false for production
        onComplete: () {
          _isInitialized = true;
          print('DEBUG: Unity Ads initialization COMPLETE');
          _preloadAds();
          completer.complete();
        },
        onFailed: (error, message) {
          print('DEBUG: Unity Ads initialization FAILED: $error $message');
          completer.completeError('Unity Ads initialization failed: $error $message');
        },
      );
      
      // Wait for initialization to complete
      return completer.future;
    } catch (e) {
      print('DEBUG: Error initializing Unity Ads: $e');
      throw e; // Re-throw to allow handling of the error in the calling code
    }
  }
  
  // Preload all ad types
  void _preloadAds() {
    print('DEBUG: AdsService._preloadAds() called');
    if (!_isInitialized || !_adsEnabled) {
      print('DEBUG: Skipping ad preload - initialized: $_isInitialized, enabled: $_adsEnabled');
      return;
    }
    
    _loadInterstitial();
    _loadRewarded();
    // Banners are loaded when shown
  }
  
  // Load interstitial ad
  void _loadInterstitial() {
    print('DEBUG: Loading interstitial ad with placementId: $interstitialPlacementId');
    UnityAds.load(
      placementId: interstitialPlacementId,
      onComplete: (placementId) => print('DEBUG: Interstitial ad loaded successfully: $placementId'),
      onFailed: (placementId, error, message) => 
          print('DEBUG: Interstitial ad load FAILED: $placementId $error $message'),
    );
  }
  
  // Load rewarded ad
  void _loadRewarded() {
    print('DEBUG: Loading rewarded ad with placementId: $rewardedPlacementId');
    UnityAds.load(
      placementId: rewardedPlacementId,
      onComplete: (placementId) => print('DEBUG: Rewarded ad loaded successfully: $placementId'),
      onFailed: (placementId, error, message) => 
          print('DEBUG: Rewarded ad load FAILED: $placementId $error $message'),
    );
  }
  
  // Show banner ad
  Widget showBannerAd({BannerSize size = BannerSize.standard}) {
    print('DEBUG: AdsService.showBannerAd() called');
    if (!_isInitialized || !_adsEnabled) {
      print('DEBUG: Skipping banner ad - initialized: $_isInitialized, enabled: $_adsEnabled');
      return const SizedBox(height: 50); // Return empty space with approximate banner height
    }
    
    print('DEBUG: Showing banner ad with placementId: $bannerPlacementId');
    return UnityBannerAd(
      placementId: bannerPlacementId,
      onLoad: (placementId) => print('DEBUG: Banner ad loaded successfully: $placementId'),
      onFailed: (placementId, error, message) => 
          print('DEBUG: Banner ad load FAILED: $placementId $error $message'),
      size: size,
    );
  }
  
  // Show interstitial ad with cooldown check
  Future<bool> showInterstitialAd() async {
    print('DEBUG: AdsService.showInterstitialAd() called');
    if (!_isInitialized || !_adsEnabled) {
      print('DEBUG: Skipping interstitial ad - initialized: $_isInitialized, enabled: $_adsEnabled');
      return false;
    }
    
    // Check cooldown to prevent showing too many ads
    final now = DateTime.now();
    if (_lastInterstitialTime != null) {
      final difference = now.difference(_lastInterstitialTime!).inSeconds;
      if (difference < interstitialCooldownSeconds) {
        print('DEBUG: Interstitial ad skipped: cooldown period ($difference/${interstitialCooldownSeconds}s)');
        return false;
      }
    }
    
    final completer = Completer<bool>();
    
    print('DEBUG: Showing interstitial ad with placementId: $interstitialPlacementId');
    UnityAds.showVideoAd(
      placementId: interstitialPlacementId,
      onComplete: (placementId) {
        print('DEBUG: Interstitial ad completed: $placementId');
        _lastInterstitialTime = now;
        _loadInterstitial(); // Preload next ad
        completer.complete(true);
      },
      onFailed: (placementId, error, message) {
        print('DEBUG: Interstitial ad failed: $placementId $error $message');
        _loadInterstitial(); // Try to reload
        completer.complete(false);
      },
      onStart: (placementId) => print('DEBUG: Interstitial ad started: $placementId'),
      onClick: (placementId) => print('DEBUG: Interstitial ad clicked: $placementId'),
      onSkipped: (placementId) {
        print('DEBUG: Interstitial ad skipped: $placementId');
        _lastInterstitialTime = now;
        completer.complete(false);
      },
    );
    
    return completer.future;
  }
  
  // Show rewarded ad
  Future<bool> showRewardedAd() async {
    print('DEBUG: AdsService.showRewardedAd() called');
    if (!_isInitialized || !_adsEnabled) {
      print('DEBUG: Skipping rewarded ad - initialized: $_isInitialized, enabled: $_adsEnabled');
      _rewardStreamController.add(false);
      return false;
    }
    
    final completer = Completer<bool>();
    
    print('DEBUG: Showing rewarded ad with placementId: $rewardedPlacementId');
    UnityAds.showVideoAd(
      placementId: rewardedPlacementId,
      onComplete: (placementId) {
        print('DEBUG: Rewarded ad completed: $placementId');
        _rewardStreamController.add(true);
        _loadRewarded(); // Preload next ad
        completer.complete(true);
      },
      onFailed: (placementId, error, message) {
        print('DEBUG: Rewarded ad failed: $placementId $error $message');
        _rewardStreamController.add(false);
        _loadRewarded(); // Try to reload
        completer.complete(false);
      },
      onStart: (placementId) => print('DEBUG: Rewarded ad started: $placementId'),
      onClick: (placementId) => print('DEBUG: Rewarded ad clicked: $placementId'),
      onSkipped: (placementId) {
        print('DEBUG: Rewarded ad skipped: $placementId');
        _rewardStreamController.add(false);
        completer.complete(false);
      },
    );
    
    return completer.future;
  }
  
  // Toggle ads state
  Future<void> setAdsEnabled(bool enabled) async {
    print('DEBUG: AdsService.setAdsEnabled() called with: $enabled');
    _adsEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('ads_enabled', enabled);
    
    if (enabled && _isInitialized) {
      _preloadAds();
    }
  }
  
  // Clean up resources
  void dispose() {
    print('DEBUG: AdsService.dispose() called');
    _rewardStreamController.close();
  }
} 