import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
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

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
  late Future<Map<String, List<Map<String, dynamic>>>> dashboardData;
  int _currentCarouselIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  // final InterstitialAdManager interstitialAdManager = InterstitialAdManager();

  @override
  void initState() {
    super.initState();
    // interstitialAdManager.loadInterstitialAd();
    dashboardData = DashboardRepository.fetchDashboardData();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: FutureBuilder<Map<String, List<Map<String, dynamic>>>>(
      future: dashboardData,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
                child: CircularProgressIndicator(color: Colors.red),
              );
            }

            if (snapshot.hasError) {
              return Center(
            child: Text(
                  'Error: ${snapshot.error}',
                  style: const TextStyle(color: Colors.white),
            ),
          );
        }

        final data = snapshot.data!;
            return SafeArea(
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                        const SizedBox(height: 20),
                        _buildCarousel(data["topRatedMovies"]!),
                        const SizedBox(height: 20),
                        _buildSection("Top Rated Movies", data["topRatedMovies"]!),
                        const SizedBox(height: 20),
                        _buildSection("Top Rated TV Shows", data["topRatedTvShows"]!),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCarousel(List<Map<String, dynamic>> movies) {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        CarouselSlider.builder(
          itemCount: movies.length,
          options: CarouselOptions(
            height: 400,
            viewportFraction: 0.8,
            enlargeCenterPage: true,
            onPageChanged: (index, reason) {
              setState(() {
                _currentCarouselIndex = index;
              });
            },
            enlargeStrategy: CenterPageEnlargeStrategy.height,
          ),
          itemBuilder: (context, index, realIndex) {
            final movie = movies[index];
            return GestureDetector(
              onTap: () {
                // interstitialAdManager.showInterstitialAd();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MovieDetailsScreen(movie: movie),
                  ),
                );
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.2),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        movie["poster"] ?? "",
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Colors.grey[900],
                          child: const Icon(Icons.error, color: Colors.white),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.7),
                              Colors.black.withOpacity(0.9),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 20,
                        left: 20,
                        right: 20,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              movie["title"] ?? "Unknown",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Colors.red, Color(0xFF8B0000)],
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.star,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        movie["imdbRating"] ?? "N/A",
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  movie["year"] ?? "",
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        Positioned(
          bottom: 20,
          child: AnimatedSmoothIndicator(
            activeIndex: _currentCarouselIndex,
            count: movies.length,
            effect: const WormEffect(
              dotWidth: 10,
              dotHeight: 10,
              activeDotColor: Colors.red,
              dotColor: Colors.grey,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSection(String title, List<Map<String, dynamic>> movies) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LibraryScreen(
                        type: title.contains("TV Shows") ? "tv_show" : "movie",
                      ),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.red, Color(0xFF8B0000)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'See All',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 250,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: movies.length,
            itemBuilder: (context, index) {
              final movie = movies[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MovieDetailsScreen(movie: movie),
                    ),
                  );
                },
                child: Container(
                  width: 150,
                  margin: const EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          movie["poster"] ?? "",
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: Colors.grey[900],
                            child: const Icon(Icons.error, color: Colors.white),
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.7),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 10,
                          left: 10,
                          right: 10,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                movie["title"] ?? "Unknown",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.star,
                                    color: Colors.amber,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    movie["imdbRating"] ?? "N/A",
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        );
      },
          ),
        ),
      ],
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
