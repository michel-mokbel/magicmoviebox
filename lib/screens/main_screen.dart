import 'package:flutter/material.dart';
import 'package:moviemagicbox/screens/search_screen.dart';
import 'package:moviemagicbox/screens/settings_screen.dart';
import 'package:moviemagicbox/screens/favorites_screen.dart';
import 'dashboard_screen.dart';


class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int currentIndex = 0; // Tracks the selected index of the bottom navigation bar
  final List<Widget> screens = [
    const DashboardScreen(),
    const SearchScreen(),
    const FavoritesScreen(),
    const Settings(),
    // const LibraryScreen(type: "tv_show"),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: 
      screens[currentIndex], // Show screen based on selected index
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) {
          setState(() {
            currentIndex = index;
          });
        },
        backgroundColor: const Color.fromARGB(255, 25, 19, 19),
        selectedItemColor: Colors.red,
        unselectedItemColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Dashboard"),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: "Search"),
          BottomNavigationBarItem(icon: Icon(Icons.watch_later), label: "Watch Later"),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Settings"),
        ],
      ),
    );
  }
}
