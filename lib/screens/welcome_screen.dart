import 'dart:async';
import 'package:flutter/material.dart';
import 'package:moviemagicbox/screens/main_screen.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';


class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _WelcomeScreenState createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;
  Timer? _timer;

  final List<String> images = [
    'lib/assets/images/First.png',
    'lib/assets/images/Second.png',
    'lib/assets/images/Third.png',
  ];

  final String title = 'Movie Magic Box';

  @override
  void initState() {
    super.initState();
    _startAutoSlide();
    _requestAttIfNeeded();
  }
  
  Future<void> _requestAttIfNeeded() async {
    try {
      // Check remote config to see if we need to show ATT
      final remoteConfig = FirebaseRemoteConfig.instance;
      final showAtt = remoteConfig.getBool('show_att');
      
      if (showAtt) {
        // Wait for UI to render before showing dialog
        await Future.delayed(const Duration(seconds: 1));
        final status = await AppTrackingTransparency.requestTrackingAuthorization();
        print('Tracking authorization status from welcome screen: $status');
      }
    } catch (e) {
      print('Failed to request tracking authorization from welcome screen: $e');
    }
  }

  void _startAutoSlide() {
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_controller.hasClients) {
        setState(() {
          _currentPage = (_currentPage + 1) % images.length;
        });
        _controller.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); // Cancel the timer to prevent memory leaks
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<String> descriptions = [
      "Your ultimate guide to movies and reviews. Elevate your entertainment experience.",
      "Discover, explore, and review movies effortlessly. Entertainment at your fingertips.",
      "The best movie lookup and review app on the market. Make your journey more entertaining.",
    ];
    return Scaffold(
      body: Stack(
        children: [
          // Background Carousel
          PageView.builder(
            controller: _controller,
            itemCount: images.length,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemBuilder: (context, index) {
              return Image.asset(
                images[index],
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              );
            },
          ),

          // Gradient Overlay
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color.fromARGB(64, 0, 0, 0),
                  Color.fromARGB(255, 0, 0, 0), 
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // Text and Indicators
          Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Title and Description
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 45,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    const Text(
                      'Your Movie Hub',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      descriptions[_currentPage],
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Page Indicator
              SmoothPageIndicator(
                controller: _controller,
                count: images.length,
                effect: const ExpandingDotsEffect(
                  activeDotColor: Colors.red,
                  dotHeight: 8,
                  dotWidth: 8,
                  dotColor: Colors.grey,
                ),
              ),
              const SizedBox(height: 30),

              // Get Started Button
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    // Navigate to the next screen
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>  const MainScreen()));
                  },
                  child: const Text(
                    'Get Started',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ],
      ),
    );
  }
}
