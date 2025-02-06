import 'package:flutter/material.dart';
// import 'package:moviemagicbox/assets/ads/banner_ad.dart';
// import 'package:moviemagicbox/assets/ads/interstitial_ad.dart';
// import 'package:moviemagicbox/assets/ads/native_ad.dart';
import 'package:moviemagicbox/screens/info_screen.dart';
import 'package:moviemagicbox/screens/library_screen.dart';
import '../repositories/dashboard_repository.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<Map<String, List<Map<String, dynamic>>>> dashboardData;
  // final InterstitialAdManager interstitialAdManager = InterstitialAdManager();

  @override
  void initState() {
    super.initState();
    // interstitialAdManager.loadInterstitialAd();
    _loadLibraryItems();
  }

  void _loadLibraryItems() async {
    try {
      final data = DashboardRepository.fetchDashboardData();
      setState(() {
        dashboardData = data; // Cache all items
      });
    } catch (e) {
      print("Error loading items: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, List<Map<String, dynamic>>>>(
      future: dashboardData,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Colors.red));
        } else if (snapshot.hasError) {
          return const Center(
            child: Text(
              "Error loading dashboard data",
              style: TextStyle(color: Colors.black),
            ),
          );
        }

        final data = snapshot.data!;
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  _buildRandomPoster(data, context),
                  _buildNavbar(),
                ],
              ),
              // const BannerAdWidget(),
              _buildSection("Trending Now",
                  data["trendingMovies"]! + data["trendingTvShows"]!, context),
              // const BannerAdWidget(),
              _buildSection("Top Rated",
                  data["topRatedMovies"]! + data["topRatedTvShows"]!, context),
              // const NativeAdWidget(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNavbar() {
    return Positioned(
      top: 65,
      left: 0,
      right: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNavbarItem("TV Shows", context),
            _buildNavbarItem("Movies", context),
          ],
        ),
      ),
    );
  }

  Widget _buildTrailerAndShareButtons(
      Map<String, dynamic> posterMovie, BuildContext context) {
    return Positioned(
      bottom: 10,
      left: 20,
      child: Row(
        children: [
          ElevatedButton(
            onPressed: () {
              // interstitialAdManager.showInterstitialAd();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MovieDetailsScreen(movie: posterMovie),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.info, color: Colors.black),
                SizedBox(width: 5),
                Text("View Info", style: TextStyle(color: Colors.black)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRandomPoster(
      Map<String, List<Map<String, dynamic>>> data, BuildContext context) {
    final combinedItems = data["trendingMovies"]! + data["trendingTvShows"]!;
    final randomPoster = (combinedItems..shuffle()).first;

    return Stack(
      children: [
        Image.network(
          randomPoster["poster"] ?? "",
          height: 620,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            height: 620,
            width: double.infinity,
            color: Colors.grey,
            child: const Center(
              child: Icon(Icons.broken_image, color: Colors.white, size: 60),
            ),
          ),
        ),
        Container(
          height: 620,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color.fromARGB(95, 0, 0, 0),
                Color.fromARGB(34, 0, 0, 0),
              ],
              begin: Alignment.topCenter,
              end: Alignment.center,
            ),
          ),
        ),
        _buildTrailerAndShareButtons(randomPoster, context),
      ],
    );
  }

  Widget _buildSection(
      String title, List<Map<String, dynamic>> items, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: _buildMovieCard(items[index], context),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMovieCard(Map<String, dynamic> movie, BuildContext context) {
    String truncatedTitle = _truncateTitle(movie["title"] ?? "Unknown Title");

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MovieDetailsScreen(movie: movie),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              movie["poster"] ?? "",
              height: 150,
              width: 100,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                height: 150,
                width: 100,
                color: Colors.grey,
                child: const Icon(Icons.broken_image, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            truncatedTitle,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _truncateTitle(String title) {
    List<String> words = title.split(' ');
    if (words.length > 2) {
      return '${words[0]} ${words[1]}...';
    }
    return title;
  }

  Widget _buildNavbarItem(String label, BuildContext context) {
    String type = label == "TV Shows" ? "tv_show" : "movie";
    return ElevatedButton(
      onPressed: () {
        // interstitialAdManager.showInterstitialAd();
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => LibraryScreen(type: type),
          ),
        );
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
