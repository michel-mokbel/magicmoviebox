# Movie Magic Box - Integration Documentation

## Table of Contents
1. [Overview](#overview)
2. [AppsFlyer Integration](#appsflyer-integration)
3. [Unity Ads Integration](#unity-ads-integration)
4. [Ad Implementation Details](#ad-implementation-details)
5. [WebView Integration](#webview-integration)
6. [Error Handling and Fallbacks](#error-handling-and-fallbacks)
7. [Testing and Troubleshooting](#testing-and-troubleshooting)

## Overview

This document outlines the implementation of AppsFlyer for attribution tracking and Unity Ads for monetization in the Movie Magic Box app. The integration includes initialization logic, error handling, fallback mechanisms, and various ad implementations throughout the application.

## AppsFlyer Integration

### SDK Setup

1. **Dependencies Added**:
   - AppsFlyer SDK dependency added to `pubspec.yaml`
   - App Tracking Transparency (ATT) package for iOS compliance

2. **Configuration in Info.plist**:
   - Added AppsFlyer App ID and Dev Key
   - Configured privacy permissions for tracking (NSUserTrackingUsageDescription)
   - Included SKAdNetwork identifiers for attribution

3. **Initialization Approach**:
   We implemented a two-step initialization pattern for AppsFlyer. First, we create an instance with the proper configuration and Game ID retrieved from remote config. Then, in a separate step, we start the tracking process only after determining if the user has granted the appropriate permissions through the ATT prompt. This separation allows us to comply with Apple's privacy guidelines while ensuring tracking is properly initialized.

### SKAdNetwork Configuration

The Info.plist file was configured with SKAdNetwork identifiers to support iOS ad attribution. This is critical for tracking ad conversions in iOS 14+ where IDFA might be restricted:

1. **Implementation Details**:
   - Added `SKAdNetworkItems` array to Info.plist
   - Included SKAdNetwork identifiers from all ad networks (Unity, Google, Facebook, etc.)
   - Removed duplicate identifiers to optimize the file size
   - Configured `NSAdvertisingAttributionReportEndpoint` for privacy-preserving attribution

2. **NSAdvertisingAttributionReportEndpoint Configuration**:
   This is a crucial part of the implementation for iOS 14.5+ to support Apple's privacy-preserving attribution. We configured the endpoint URL to point to AppsFlyer's SKAdNetwork server (https://appsflyer-skadnetwork.com/). This enables Privacy-Preserving Ad Attribution reports to be sent to AppsFlyer and is required for complete attribution data in iOS 14.5 and newer devices.

3. **SKAdNetwork Identifiers**:
   We included a comprehensive list of SKAdNetwork identifiers from various ad networks in the Info.plist file. These identifiers allow the iOS system to attribute app installations to specific ad campaigns even when IDFA is not available. The list contains identifiers like "v72qych5uu.skadnetwork", "4fzdc2evr5.skadnetwork", "cstr6suwn9.skadnetwork", and many others covering all major ad networks.

4. **Key Benefits**:
   - Enables conversion tracking even when IDFA is unavailable
   - Improves ad attribution accuracy on iOS 14+ devices
   - Supports all major ad networks in the ecosystem
   - Complies with Apple's privacy requirements

5. **Maintenance Considerations**:
   - Regularly update the list with new identifiers from ad network partners
   - Remove duplicates to keep the file size optimized
   - Validate the list against Apple's requirements

### Key Implementation Details

1. **Remote Config Integration**:
   - Dev Key retrieved from Firebase Remote Config with fallback 
   - Remote Config used to determine if ATT prompt should be shown (`show_att` parameter)

2. **Device Info Collection**:
   We collect various device identifiers for attribution purposes. This includes the device UUID (generated and stored if not present), the IDFA (Advertising Identifier, only if authorized), the IDFV (Vendor Identifier), the bundle ID, and the AppsFlyer ID. These identifiers are used to track user journeys and attribute conversions properly.

3. **User Journey Tracking**:
   - Installation completion event
   - Session start events
   - User type tracking (new vs. returning)

4. **Deep Link Handling**:
   - Configuration for in-app attribution callbacks
   - `onAppOpenAttribution` handler for deep link data processing

## Unity Ads Integration

### SDK Setup

1. **Dependencies Added**:
   - Unity Ads Plugin added to `pubspec.yaml`
   - Shared Preferences for managing ad settings

2. **Singleton Service Pattern**:
   - Created `AdsService` as a singleton to manage ads throughout the app
   - All ad-related functionality centralized in this service

3. **Initialization with Timeout**:
   We implemented a timeout mechanism during the Unity Ads initialization to prevent the app from getting stuck if there are network issues or other problems. The initialization process starts by creating a completer that will resolve after the Unity Ads SDK successfully initializes. We set a 5-second timeout that automatically completes the process with a failure status if Unity Ads doesn't respond within that time frame. This ensures the app continues to function even when ad services are unavailable.

### Ad Types Implemented

1. **Banner Ads**:
   - Placement ID: "Banner_iOS"
   - Used in dashboard, info screen, and reviews section
   - Graceful fallback to empty space if ads fail to load

2. **Interstitial Ads**:
   - Placement ID: "Interstitial_iOS"
   - Implemented with cooldown logic (60 seconds between ads)
   - Used between screen transitions

3. **Rewarded Ads**:
   - Placement ID: "Rewarded_iOS"
   - Implementation includes reward confirmation
   - Used for features like adding to favorites and handling WebView errors

## Ad Implementation Details

### Banner Ad Implementation

Banner ads are implemented in multiple locations:
- Top and bottom of the Cinema screens
- Reviews section in the movie details screen
- Between sections in the movie overview tab

Implementation approach: We created a standard pattern for banner ads that includes a container with fixed height (60 pixels) that displays either the ad content or an empty space with the same dimensions if ads fail to load. This ensures UI consistency regardless of ad availability.

### Interstitial Ad Implementation

Interstitial ads are shown during navigation events with cooldown logic to prevent ad fatigue. Our implementation includes several key components:

1. **Initialization Check**: Before showing an interstitial ad, we verify if the ads service is properly initialized and enabled.

2. **Cooldown Management**: To prevent showing too many interstitial ads in a short period, we implemented a cooldown mechanism. We track the timestamp of the last shown interstitial ad and only show a new one if at least 60 seconds have passed.

3. **Lifecycle Management**: We properly handle the ad lifecycle, including completion, failures, and user interactions (clicks or skips). After an ad completes or fails, we immediately preload the next ad to ensure one is ready for the next opportunity.

### Rewarded Ad Implementation

Rewarded ads are implemented in the following scenarios:
1. **Adding to favorites** - In the InfoScreen when users want to add content to Watch Later
2. **Error handling** - When WebView encounters errors or navigation to error:// URLs
3. **Splash screen** - When the app starts with empty URL from remote config

Implementation approach: We implemented a reliable pattern for rewarded ads that includes timeout protection. This prevents the app from getting stuck if the ad fails to load or display. We use a Future.any approach that completes either when the ad completes or after a 5-second timeout, whichever comes first. This is wrapped in try-catch blocks to handle any unexpected errors during the ad display process.

## WebView Integration

The app implements a WebView-based experience when specific conditions are met, with tight integration with AppsFlyer for tracking and Unity Ads for monetization on error cases.

### Remote Config to WebView Flow

1. **URL Source Configuration**:
   - URL is fetched from Firebase Remote Config
   - If URL is present, app launches in WebView mode
   - If URL is empty, app shows the native experience with SplashWithAdScreen

2. **Parameter Injection**:
   We enhance the URL from remote config by injecting device-specific parameters. This includes replacing placeholders in the URL with actual device information such as bundle ID, UUID, IDFA (if available), IDFV, and AppsFlyer ID. This allows for better tracking and personalization of the web content.

3. **WebView Initialization**:
   The WebView is initialized with unrestricted JavaScript mode and custom navigation delegates to handle page events. We configure the controller to handle page start/finish events, navigation requests, and error handling. This setup ensures that we can properly monitor the WebView state and respond to various events.

### Error Handling with Ad Integration

1. **WebView Error Detection**:
   - Monitors for WebView errors via `onWebResourceError` callback
   - Detects special error:// URL scheme via `onNavigationRequest`
   - Both error types trigger the ad display flow

2. **Error to Ad Display Flow**:
   When a WebView error is detected, we implement a multi-step process: First, we show a loading indicator to provide visual feedback to the user. Then, we check if ads are initialized and enabled before attempting to show a rewarded ad. We include timeout protection to ensure the process doesn't get stuck waiting for an ad. Finally, regardless of whether the ad was shown successfully, we navigate to the welcome screen to ensure the user can continue using the app.

### Custom URL Scheme Handling

1. **Error URL Detection**:
   We implemented a special URL scheme handler that detects URLs starting with "error://". When such a URL is encountered during navigation, we prevent the navigation and instead handle it similar to a WebView error. This allows the web content to trigger specific app behaviors.

2. **Benefits of Custom URL Schemes**:
   - Allows remote servers to trigger specific app behaviors
   - Enables controlled fallback from WebView to native experience
   - Provides flexibility for error handling without relying on HTTP error codes

### Tracking Considerations

1. **AppsFlyer Integration**:
   - WebView URLs include AppsFlyer ID for continued attribution
   - Tracking is properly initialized before WebView is launched
   - ATT permissions are requested based on remote config setting

2. **Privacy Considerations**:
   - Device identifiers are only passed if proper permissions are granted
   - Fallback approaches for limited tracking environments
   - Compliant with App Store policies for tracking and attribution

## Error Handling and Fallbacks

### Graceful Degradation Pattern

The app implements a graceful degradation approach to handle ad failures:

1. **Timeout Mechanism**:
   - 5-second timeout for Unity Ads initialization
   - 5-second timeout for ad display operations
   - 6-second timeout in the main function for overall ad subsystem

2. **Initialization Handling**:
   In the main function, we implemented a robust initialization approach for the AdsService. We use Future.any to race between the actual initialization process and a 6-second timeout. This ensures that even if the ad initialization process hangs indefinitely, the app will proceed after the timeout period. We catch any errors during this process and set adsInitialized to false, allowing the app to continue without ads.

3. **Feature Fallback**:
   - Watch Later feature works without ads if ads are not initialized
   - Banner ads replaced with empty spaces of correct height
   - Navigation continues even if ads fail to load

### Conditional Ad Display

All ad display logic includes checks for initialization status. Before attempting to show any ad, we verify both the initialization status and whether ads are enabled. If either condition is not met, we proceed without showing the ad, ensuring the app's functionality is preserved regardless of ad availability.

## Testing and Troubleshooting

### Testing Methodology

1. **Test Mode Configuration**:
   - Unity Ads can be initialized in test mode for development
   - Set `testMode: true` in the initialization method

2. **Debug Logging**:
   - Extensive debug logs implemented throughout the ad flow
   - Prefix pattern: 'DEBUG: [Component] - [Action]'

3. **Common Issues and Solutions**:

   | Issue | Solution |
   |-------|----------|
   | App hangs during ad initialization | Implementation of timeout mechanism |
   | Ads not showing | Checking isInitialized flag before attempting to show |
   | No ad revenue | Verifying correct placement IDs |
   | ATT prompt issues | Added delay before prompt to ensure UI is ready |

### Key Debugging Points

- Check logs for "Unity Ads initialization COMPLETE" message
- Verify `_isInitialized` flag is true before showing ads
- Monitor "Ad display timed out" messages that indicate ad loading issues
- Check for specific error messages in the "Unity Ads initialization FAILED" logs 