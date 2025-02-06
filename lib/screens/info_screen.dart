import 'package:flutter/material.dart';
// import 'package:moviemagicbox/assets/ads/banner_ad.dart';
// import 'package:moviemagicbox/assets/ads/interstitial_ad.dart';
// import 'package:moviemagicbox/assets/ads/native_ad.dart';
import 'package:url_launcher/url_launcher.dart';
import '../repositories/dashboard_repository.dart';
import '../services/favorites_service.dart';
import '../services/notification_service.dart';
import '../services/review_service.dart';
import 'review_screen.dart';

class MovieDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> movie; // Movie data passed dynamically

  const MovieDetailsScreen({super.key, required this.movie});

  @override
  State<MovieDetailsScreen> createState() => _MovieDetailsScreenState();
}

class _MovieDetailsScreenState extends State<MovieDetailsScreen> {
  late Future<Map<String, List<Map<String, dynamic>>>> dashboardData;
  late Future<Review?> userReview;
  late Future<List<Review>> allReviews;
  // final InterstitialAdManager AdManager = InterstitialAdManager();
  bool _isFavorite = false;
  late String _movieId;

  @override
  void initState() {
    super.initState();
    _movieId = widget.movie['imdbID'] ?? '${widget.movie["title"]}_${widget.movie["year"]}';
    // interstitialAdManager.loadInterstitialAd();
    dashboardData = DashboardRepository.fetchDashboardData();
    _checkFavoriteStatus();
    _loadReviews();
  }

  void _loadReviews() {
    userReview = ReviewService.getReviewForMedia(_movieId);
    allReviews = ReviewService.getReviewsForMedia(_movieId);
  }

  Future<void> _checkFavoriteStatus() async {
    final isFav = await FavoritesService.isFavorite(_movieId);
    setState(() {
      _isFavorite = isFav;
    });
  }

  Future<void> _toggleFavorite() async {
    setState(() {
      _isFavorite = !_isFavorite;
    });

    if (_isFavorite) {
      await FavoritesService.addToFavorites(widget.movie);
    } else {
      await FavoritesService.removeFromFavorites(_movieId);
    }
  }

  Future<void> _showReminderDialog() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate != null) {
      if (!context.mounted) return;
      
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (pickedTime != null) {
        final DateTime scheduledTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        await NotificationService.instance.scheduleMovieReminder(
          movieTitle: widget.movie['title'],
          scheduledTime: scheduledTime,
          movieId: _movieId,
          context: context,
        );

        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reminder set successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
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

  Widget _buildReviewsSection() {
    return FutureBuilder<Review?>(
      future: userReview,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.red));
        }

        final existingReview = snapshot.data;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Reviews',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ReviewScreen(
                            media: widget.movie,
                            type: widget.movie['Type'] ?? 'movie',
                            existingReview: existingReview,
                          ),
                        ),
                      );

                      if (result == true) {
                        setState(() {
                          _loadReviews();
                        });
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      existingReview == null ? 'Write Review' : 'Edit Review',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            FutureBuilder<List<Review>>(
              future: allReviews,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.red));
                }

                final reviews = snapshot.data ?? [];

                if (reviews.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'No reviews yet. Be the first to review!',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: reviews.length,
                  itemBuilder: (context, index) {
                    final review = reviews[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      color: Colors.grey[900],
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    review.title,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Row(
                                  children: [
                                    const Icon(Icons.star, color: Colors.amber, size: 20),
                                    const SizedBox(width: 4),
                                    Text(
                                      review.rating.toStringAsFixed(1),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              review.content,
                              style: const TextStyle(color: Colors.white),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Posted on ${_formatDate(review.timestamp)}',
                              style: TextStyle(color: Colors.grey[400], fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
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
        actions: [
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.watch_later : Icons.watch_later_outlined,
              color: Colors.red,
            ),
            onPressed: _toggleFavorite,
          ),
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.red),
            onPressed: _showReminderDialog,
          ),
        ],
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
              length: 3,
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
                      Tab(text: "Reviews"),
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

                        // Reviews
                        _buildReviewsSection(),

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
