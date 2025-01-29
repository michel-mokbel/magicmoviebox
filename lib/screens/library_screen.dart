import 'package:flutter/material.dart';
import 'package:moviemagicbox/assets/ads/banner_ad.dart';
import 'package:moviemagicbox/screens/info_screen.dart';
import '../services/movie_service.dart';

class LibraryScreen extends StatefulWidget {
  final String type; // Accept 'movie' or 'tv_show'
  const LibraryScreen({super.key, required this.type});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  late Future<List<Map<String, dynamic>>> libraryItems;
  late String selectedType;

  @override
  void initState() {
    super.initState();
    selectedType = widget.type;
    libraryItems = MovieService.fetchAllByType(selectedType);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: Colors.white,
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          selectedType == "movie" ? "Movies Library" : "TV Shows Library",
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black,
      ),
      backgroundColor: Colors.black,
      body: Column(
        children: [
          // const BannerAdWidget(),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: libraryItems,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.red),
                  );
                } else if (snapshot.hasError) {
                  return const Center(
                    child: Text(
                      "Error loading library items",
                      style: TextStyle(color: Colors.white),
                    ),
                  );
                }

                final items = snapshot.data ?? [];
                if (items.isEmpty) {
                  return const Center(
                    child: Text(
                      "No items available",
                      style: TextStyle(color: Colors.white),
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(8.0),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 0.7,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    return _buildMovieCard(items[index], context);
                  },
                );
              },
            ),
            
          ),

        ],
      ),
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
}
