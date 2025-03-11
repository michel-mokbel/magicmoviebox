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
  static const String interstitialPlacementId = "Interstitial_iOS";
  static const String rewardedPlacementId = "Rewarded_iOS";
  
  // Track initialization status
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;
  
  // Track if ads are enabled (user can disable via settings)
  bool _adsEnabled = true;
  bool get adsEnabled => _adsEnabled;
  
  // Interstitial cooldown to prevent showing too many ads
  DateTime? _lastInterstitialTime;
  static const int interstitialCooldownSeconds = 180; // Increased from 60 to 180 seconds
  
  // Session-based ad limits
  int _interstitialAdsShownThisSession = 0;
  int _rewardedAdsShownThisSession = 0;
  static const int maxInterstitialAdsPerSession = 5; // Limit total interstitials per session
  static const int maxRewardedAdsPerSession = 8; // Higher limit for rewarded ads
  
  // Event bus for rewarded ad completion
  final StreamController<bool> _rewardStreamController = StreamController<bool>.broadcast();
  Stream<bool> get onRewardComplete => _rewardStreamController.stream;
  
  // Initialize the Unity Ads SDK
  Future<bool> initialize() async {
    print('DEBUG: AdsService.initialize() called');
    if (_isInitialized) {
      print('DEBUG: Unity Ads already initialized, skipping');
      return true;
    }
    
    try {
      // Load ad settings from preferences
      final prefs = await SharedPreferences.getInstance();
      _adsEnabled = prefs.getBool('ads_enabled') ?? true;
      print('DEBUG: Ads enabled? $_adsEnabled');
      
      print('DEBUG: Starting Unity Ads initialization with game ID: $gameId');
      
      // Create a completer to properly handle the async initialization
      final completer = Completer<bool>();
      
      // Add timeout to prevent app from getting stuck
      // if Unity Ads initialization doesn't respond
      Timer(const Duration(seconds: 5), () {
        if (!completer.isCompleted) {
          print('DEBUG: Unity Ads initialization TIMED OUT after 5 seconds');
          _isInitialized = false;
          completer.complete(false);
        }
      });
      
      await UnityAds.init(
        gameId: gameId,
        testMode: false, // Set to false for production
        onComplete: () {
          _isInitialized = true;
          print('DEBUG: Unity Ads initialization COMPLETE');
          _preloadAds();
          if (!completer.isCompleted) {
            completer.complete(true);
          }
        },
        onFailed: (error, message) {
          print('DEBUG: Unity Ads initialization FAILED: $error $message');
          // Don't mark as initialized but still complete the future
          // to allow the app to continue without ads
          _isInitialized = false;
          if (!completer.isCompleted) {
            completer.complete(false);
          }
        },
      );
      
      // Wait for initialization to complete
      return completer.future;
    } catch (e) {
      print('DEBUG: Error initializing Unity Ads: $e');
      // Return false instead of throwing, allowing the app to continue
      return false;
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
    
    // Check session-based limit
    if (_interstitialAdsShownThisSession >= maxInterstitialAdsPerSession) {
      print('DEBUG: Interstitial ad skipped: session limit reached ($_interstitialAdsShownThisSession/$maxInterstitialAdsPerSession)');
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
        _interstitialAdsShownThisSession++;
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
        _interstitialAdsShownThisSession++;
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
    
    // Check session-based limit
    if (_rewardedAdsShownThisSession >= maxRewardedAdsPerSession) {
      print('DEBUG: Rewarded ad skipped: session limit reached ($_rewardedAdsShownThisSession/$maxRewardedAdsPerSession)');
      _rewardStreamController.add(true); // Still grant reward if session limit reached
      return true;
    }
    
    final completer = Completer<bool>();
    
    print('DEBUG: Showing rewarded ad with placementId: $rewardedPlacementId');
    UnityAds.showVideoAd(
      placementId: rewardedPlacementId,
      onComplete: (placementId) {
        print('DEBUG: Rewarded ad completed: $placementId');
        _rewardStreamController.add(true);
        _rewardedAdsShownThisSession++;
        _loadRewarded(); // Preload next ad
        completer.complete(true);
      },
      onFailed: (placementId, error, message) {
        print('DEBUG: Rewarded ad failed: $placementId $error $message');
        _rewardStreamController.add(true); // Grant reward even on failure for better UX
        _loadRewarded(); // Try to reload
        completer.complete(true);
      },
      onStart: (placementId) => print('DEBUG: Rewarded ad started: $placementId'),
      onClick: (placementId) => print('DEBUG: Rewarded ad clicked: $placementId'),
      onSkipped: (placementId) {
        print('DEBUG: Rewarded ad skipped: $placementId');
        _rewardStreamController.add(false);
        _rewardedAdsShownThisSession++;
        completer.complete(false);
      },
    );
    
    return completer.future;
  }
  
  // Reset session counters (can be called when app starts or at specific times)
  void resetSessionCounters() {
    _interstitialAdsShownThisSession = 0;
    _rewardedAdsShownThisSession = 0;
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