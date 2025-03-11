import 'package:flutter/material.dart';
// import 'package:moviemagicbox/assets/ads/banner_ad.dart';
// import 'package:moviemagicbox/assets/ads/interstitial_ad.dart';
// import 'package:moviemagicbox/assets/ads/native_ad.dart';
import 'package:url_launcher/url_launcher.dart';
import '../repositories/dashboard_repository.dart';
import '../services/favorites_service.dart';
import '../services/review_service.dart';
import '../services/streaming_service.dart';
import '../services/ads_service.dart';
import 'review_screen.dart';

class MovieDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> movie;

  const MovieDetailsScreen({super.key, required this.movie});

  @override
  State<MovieDetailsScreen> createState() => _MovieDetailsScreenState();
}

class _MovieDetailsScreenState extends State<MovieDetailsScreen>
    with SingleTickerProviderStateMixin {
  late Future<Map<String, List<Map<String, dynamic>>>> dashboardData;
  late Future<Review?> userReview;
  late Future<List<Review>> allReviews;
  late Future<Map<String, dynamic>> streamingData;
  // final InterstitialAdManager AdManager = InterstitialAdManager();
  final AdsService _adsService = AdsService();
  bool _isFavorite = false;
  late String _movieId;
  late TabController _tabController;
  late ScrollController _scrollController;
  bool _showTitle = false;

  @override
  void initState() {
    super.initState();
    _movieId = widget.movie['imdbID'] ??
        '${widget.movie["title"]}_${widget.movie["year"]}';
    // interstitialAdManager.loadInterstitialAd();
    dashboardData = DashboardRepository.fetchDashboardData();
    _checkFavoriteStatus();
    _loadReviews();
    streamingData = StreamingService.getStreamingAvailability(
        widget.movie["title"],
        type: widget.movie["type"] ?? 'movie');
    _tabController = TabController(length: 3, vsync: this);
    _scrollController = ScrollController()
      ..addListener(() {
        setState(() {
          _showTitle = _scrollController.offset > 200;
        });
      });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
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
    print(
        'DEBUG: InfoScreen - _toggleFavorite called, current status: $_isFavorite');
    // If already a favorite, just remove it without showing an ad
    if (_isFavorite) {
      print('DEBUG: InfoScreen - Removing from favorites');
      setState(() {
        _isFavorite = false;
      });
      await FavoritesService.removeFromFavorites(_movieId);
      return;
    }

    // Get favorites count to determine if ad should be shown
    final favoriteCount = await FavoritesService.getFavoritesCount();
    final shouldShowAd = favoriteCount % 3 == 0; // Only show ad every third favorite
    
    print('DEBUG: InfoScreen - Current favorites count: $favoriteCount, should show ad: $shouldShowAd');

    // If ads are not initialized, disabled, or we're not showing an ad this time
    if (!_adsService.isInitialized || !_adsService.adsEnabled || !shouldShowAd) {
      print('DEBUG: InfoScreen - Skipping ad, adding directly to favorites');
      // Add to favorites without showing ad
      setState(() {
        _isFavorite = true;
      });
      await FavoritesService.addToFavorites(widget.movie);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Added to Watch Later!'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    // If ads are available and we should show an ad, show rewarded ad
    // Show loading indicator
    print('DEBUG: InfoScreen - Showing loading indicator for favorites ad');
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );

    // Show rewarded ad
    print('DEBUG: InfoScreen - About to show rewarded ad for favorites');
    bool rewardEarned = false;
    try {
      rewardEarned = await Future.any([
        _adsService.showRewardedAd(),
        Future.delayed(const Duration(seconds: 5), () {
          print('InfoScreen: Ad display timed out for favorites');
          return false;
        })
      ]);
    } catch (e) {
      print('InfoScreen: Error showing ad for favorites: $e');
    }
    print(
        'DEBUG: InfoScreen - Rewarded ad for favorites completed, reward earned: $rewardEarned');

    // Dismiss loading indicator
    if (context.mounted) {
      print('DEBUG: InfoScreen - Dismissing loading indicator');
      Navigator.of(context).pop();
    }

    // Always add to favorites, even if ad was skipped or failed
    // This provides a better user experience while still showing ads sometimes
    print('DEBUG: InfoScreen - Adding to favorites');
    setState(() {
      _isFavorite = true;
    });
    await FavoritesService.addToFavorites(widget.movie);

    if (context.mounted) {
      print('DEBUG: InfoScreen - Showing success snackbar');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Added to Watch Later!'),
          duration: Duration(seconds: 2),
        ),
      );
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

  // Show rewarded ad and play trailer without confirmation dialog
  Future<void> _showAdAndPlayTrailer(String query) async {
    print('DEBUG: InfoScreen - _showAdAndPlayTrailer called for query: $query');
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        print('DEBUG: InfoScreen - Showing loading indicator for trailer ad');
        return const Center(
          child: CircularProgressIndicator(color: Colors.red),
        );
      },
    );


    // Dismiss loading indicator
    if (context.mounted) {
      print('DEBUG: InfoScreen - Dismissing loading indicator');
      Navigator.of(context).pop();
    }

    
      print('DEBUG: InfoScreen - Launching YouTube search for: $query');
      _launchYouTubeSearch(query);
  }

  Widget _buildReviewsSection() {
    return FutureBuilder<Review?>(
      future: userReview,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Colors.red));
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
            // Add banner ad in reviews section

            FutureBuilder<List<Review>>(
              future: allReviews,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(color: Colors.red));
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
                                    const Icon(Icons.star,
                                        color: Colors.amber, size: 20),
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
                              style: TextStyle(
                                  color: Colors.grey[400], fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            Center(
              child: SizedBox(
                height: 60,
                child: _adsService.showBannerAd(),
              ),
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
      backgroundColor: Colors.black,
      body: NestedScrollView(
        controller: _scrollController,
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 500,
            floating: false,
            pinned: true,
            backgroundColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              title: _showTitle
                  ? Text(
                      widget.movie["title"],
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    widget.movie["poster"] ?? "",
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
                          Colors.black.withOpacity(0.5),
                          Colors.black,
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 60,
                    left: 16,
                    right: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.movie["title"],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: _getChipsData()
                              .map(
                                (chipData) => Container(
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
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        chipData['icon'] as IconData,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        chipData['label'],
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
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
        ],
        body: Column(
          children: [
            Container(
              decoration: const BoxDecoration(
                color: Colors.black,
              ),
              child: TabBar(
                controller: _tabController,
                indicatorColor: Colors.white,
                indicatorWeight: 3,
                tabs: const [
                  Tab(text: "Overview"),
                  Tab(text: "Watch"),
                  Tab(text: "Reviews"),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildOverviewTab(),
                  _buildWatchTab(),
                  _buildReviewsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Synopsis",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ExpandableText(text: widget.movie["plot"] ?? "No plot available."),
          const SizedBox(height: 24),
          // Add banner ad between synopsis and cast
          Center(
            child: SizedBox(
              height: 60,
              child: _adsService.showBannerAd(),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: (widget.movie["cast"] as List<String>? ?? [])
                .map(
                  (actor) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      actor,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildWatchTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.red, Color(0xFF8B0000)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.play_circle_outline,
                color: Colors.white,
              ),
            ),
            title: Text(
              "${widget.movie["title"]} Trailer",
              style: const TextStyle(color: Colors.white),
            ),
            subtitle: const Text(
              "Watch Now",
              style: TextStyle(color: Colors.grey),
            ),
            onTap: () => _showAdAndPlayTrailer(widget.movie["title"]),
          ),
          const Divider(color: Colors.grey),
          // Add banner ad between trailer and streaming options

          FutureBuilder<Map<String, dynamic>>(
            future: streamingData,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.red),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error loading streaming data: ${snapshot.error}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                );
              }

              final streamingInfo =
                  snapshot.data?['result']?[0]?['streamingInfo']?['ae'];
              if (streamingInfo == null || streamingInfo.isEmpty) {
                return const Center(
                  child: Text(
                    'No streaming options available',
                    style: TextStyle(color: Colors.grey),
                  ),
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      "Available on:",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ...streamingInfo
                      .map<Widget>(
                        (service) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey[900],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: service["service"] == "netflix"
                                      ? [Colors.red, const Color(0xFF8B0000)]
                                      : [Colors.blue, Colors.blueAccent],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                service["service"] == "netflix"
                                    ? Icons.play_circle_filled
                                    : Icons.shopping_cart,
                                color: Colors.white,
                              ),
                            ),
                            title: Text(
                              "${service["service"].toString().toUpperCase()} - ${service["streamingType"]}",
                              style: const TextStyle(color: Colors.white),
                            ),
                            subtitle: service["price"] != null
                                ? Text(
                                    service["price"]["formatted"],
                                    style: const TextStyle(color: Colors.grey),
                                  )
                                : null,
                            trailing: TextButton(
                              onPressed: () async {
                                final url = Uri.parse(service["link"]);
                                if (await canLaunchUrl(url)) {
                                  await launchUrl(url,
                                      mode: LaunchMode.externalApplication);
                                }
                              },
                              style: TextButton.styleFrom(
                                backgroundColor: Colors.red,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              child: Text(
                                service["streamingType"] == "subscription"
                                    ? "Watch Now"
                                    : "Buy/Rent",
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                  Container(
                    margin: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 16),
                    height: 60,
                    child: _adsService.showBannerAd(),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsTab() {
    return _buildReviewsSection();
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
