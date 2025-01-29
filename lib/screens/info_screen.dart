import 'package:flutter/material.dart';
import 'package:moviemagicbox/assets/ads/banner_ad.dart';
import 'package:moviemagicbox/assets/ads/interstitial_ad.dart';
import 'package:moviemagicbox/assets/ads/native_ad.dart';
import 'package:url_launcher/url_launcher.dart';
import '../repositories/dashboard_repository.dart';

class MovieDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> movie; // Movie data passed dynamically

  const MovieDetailsScreen({super.key, required this.movie});

  @override
  State<MovieDetailsScreen> createState() => _MovieDetailsScreenState();
}

class _MovieDetailsScreenState extends State<MovieDetailsScreen> {
  late Future<Map<String, List<Map<String, dynamic>>>> dashboardData;
    final InterstitialAdManager interstitialAdManager = InterstitialAdManager();


  @override
  void initState() {
    super.initState();
        interstitialAdManager.loadInterstitialAd();

    dashboardData = DashboardRepository.fetchDashboardData();
  }

  void _launchYouTubeSearch(String query) async {
    final Uri url = Uri.parse(
        "https://www.youtube.com/results?search_query=$query official trailer");
    if (!await launchUrl(
      url,
      mode: LaunchMode.externalApplication,
    )) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          widget.movie["title"],
          style: const TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      backgroundColor: Colors.black,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Poster Image
            Stack(
              children: [
                Image.network(
                  widget.movie["poster"] ?? "",
                  height: 500,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 300,
                    width: double.infinity,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),

            // Movie Title and Details
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    widget.movie["title"] ?? "Unknown Title",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Additional Info
                  SizedBox(
                    height: 45, // Adjust the height of the carousel as needed
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal, // Horizontal scrolling
                      itemCount: _getChipsData().length,
                      itemBuilder: (context, index) {
                        final chipData = _getChipsData()[index];
                        return Padding(
                          padding: const EdgeInsets.only(
                              right: 8.0), // Add spacing between chips
                          child: _buildChip(
                              chipData['icon'] as IconData, chipData['label']),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 16),
                  // Genre and Description
                  ExpandableText(
                    text: widget.movie["plot"] ??
                        "No description available for this movie.",
                  ),
                ],
              ),
            ),

            const Divider(color: Colors.grey),

            // Trailers and More Like This
            DefaultTabController(
              length: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // const BannerAdWidget(),
                  const TabBar(
                    labelColor: Colors.red,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: Colors.red,
                    tabs: [
                      Tab(text: "Trailers"),
                      Tab(text: "More Like This"),
                    ],
                  ),
                  SizedBox(
                    height: 590,
                    child: TabBarView(
                      children: [
                        // Trailers

                        ListTile(
                          leading: const Icon(
                            Icons.play_circle_outline,
                            color: Colors.white,
                          ),
                          title: Text(
                            "${widget.movie["title"]} Trailer",
                            style: const TextStyle(color: Colors.white),
                          ),
                          subtitle: const Text(
                            "Watch Now",
                            style: TextStyle(color: Colors.grey),
                          ),
                          onTap: () {
                            // interstitialAdManager.showInterstitialAd();
                            _launchYouTubeSearch(widget.movie["title"]);
                          },
                        ),

                        // More Like This Section
                        FutureBuilder<Map<String, List<Map<String, dynamic>>>>(
                          future: dashboardData,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.red,
                                ),
                              );
                            } else if (snapshot.hasError) {
                              return const Center(
                                child: Text(
                                  "Error loading recommendations.",
                                  style: TextStyle(color: Colors.white),
                                ),
                              );
                            }

                            final data = snapshot.data!;
                            final allMovies = data["topRatedMovies"]! +
                                data["topRatedTvShows"]!;
                            allMovies.shuffle();
                            final carousel1 = allMovies.take(8).toList();

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 16),
                                _buildCarousel("Similar Movies", carousel1),
                                // const NativeAdWidget()
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(IconData icon, String label) {
    return Chip(
      avatar: Icon(icon, size: 16, color: Colors.white),
      label: Text(label, style: const TextStyle(color: Colors.white)),
      backgroundColor: Colors.grey.shade800,
    );
  }

  List<Map<String, dynamic>> _getChipsData() {
    return [
      {'icon': Icons.star, 'label': widget.movie["imdbRating"] ?? "N/A"},
      {'icon': Icons.calendar_today, 'label': widget.movie["year"] ?? "N/A"},
      {
        'icon': Icons.table_chart_outlined,
        'label': widget.movie["genre"] ?? "N/A"
      },
    ];
  }

  Widget _buildCarousel(String title, List<Map<String, dynamic>> movies) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: movies.length,
            itemBuilder: (context, index) {
              final movie = movies[index];
              return Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: GestureDetector(
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
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                            height: 150,
                            width: 100,
                            color: Colors.grey,
                            child: const Icon(Icons.broken_image,
                                color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class ExpandableText extends StatefulWidget {
  final String text;

  const ExpandableText({super.key, required this.text});

  @override
  State<ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<ExpandableText> {
  bool isExpanded = false; // Tracks if the text is expanded

  @override
  Widget build(BuildContext context) {
    final int maxLines = isExpanded ? 100 : 2; // Show 3 lines initially

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.text,
          style: const TextStyle(color: Colors.white),
          maxLines: maxLines,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () {
            setState(() {
              isExpanded = !isExpanded; // Toggle expanded state
            });
          },
          child: Text(
            isExpanded ? "Show Less" : "Show More",
            style: const TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
