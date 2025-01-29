import 'package:flutter/material.dart';
import 'package:moviemagicbox/assets/ads/banner_ad.dart';
import 'package:moviemagicbox/screens/info_screen.dart';
import '../services/movie_service.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late Future<List<Map<String, dynamic>>> libraryItems;
  String selectedType = "movie"; // Default to movies
  String searchQuery = ""; // Store the current search query
  List<Map<String, dynamic>> allItems = []; // Cache all fetched items
  List<Map<String, dynamic>> filteredItems = []; // Items matching the search query

  @override
  void initState() {
    super.initState();
    _loadLibraryItems();
  }

  void _loadLibraryItems() async {
    try {
      final items = await MovieService.fetchAllByType(selectedType);
      setState(() {
        allItems = items; // Cache all items
        filteredItems = items; // Initially display all items
      });
    } catch (e) {
      print("Error loading items: $e");
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      searchQuery = query.toLowerCase();
      filteredItems = allItems.where((item) {
        final title = (item["title"] ?? "").toLowerCase();
        return title.contains(searchQuery);
      }).toList();
    });
  }

  void _onTypeChanged(String type) {
    setState(() {
      selectedType = type;
      searchQuery = ""; // Reset search query
      filteredItems = [];
      allItems = [];
    });
    _loadLibraryItems(); // Fetch new data for the selected type
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black,),
          onPressed: () {

          },
        ),
        title: const Text(
          "Search",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: DropdownButton<String>(
              dropdownColor: Colors.black,
              value: selectedType,
              items: const [
                DropdownMenuItem(
                  value: "movie",
                  child: Text("Movies", style: TextStyle(color: Colors.white)),
                ),
                DropdownMenuItem(
                  value: "tv_show",
                  child: Text("TV Shows", style: TextStyle(color: Colors.white)),
                ),
              ],
              onChanged: (type) {
                if (type != null) {
                  _onTypeChanged(type);
                }
              },
              underline: Container(),
              icon: const Icon(Icons.filter_list, color: Colors.white),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: _onSearchChanged,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Search by name",
                hintStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: Colors.grey.shade800,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(Icons.search, color: Colors.white),
              ),
            ),
          ),
        ),
      ),
      backgroundColor: Colors.black,
      body: filteredItems.isEmpty
          ? const Center(
              child: Text(
                "No results found.",
                style: TextStyle(color: Colors.white),
              ),
            )
          : Column(
            children: [
              // const BannerAdWidget(),
              Expanded(
                child: GridView.builder(
                    padding: const EdgeInsets.all(8.0),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 0.7,
                    ),
                    itemCount: filteredItems.length,
                    itemBuilder: (context, index) {
                      return _buildMovieCard(filteredItems[index], context);
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
