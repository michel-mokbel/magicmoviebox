import 'package:flutter/material.dart';
import 'package:moviemagicbox/screens/search_screen.dart';
import 'package:moviemagicbox/screens/settings_screen.dart';
import 'package:moviemagicbox/screens/favorites_screen.dart';
import 'package:moviemagicbox/screens/cinemas_screen.dart';
import 'package:flutter_html/flutter_html.dart';
import '../services/api_service.dart';
import '../services/ads_service.dart';
import 'dashboard_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with SingleTickerProviderStateMixin {
  int currentIndex = 0;
  bool _isChatOpen = false;
  late AnimationController _animationController;
  final List<Widget> screens = [
    const DashboardScreen(),
    const SearchScreen(),
    const CinemasScreen(),
    const FavoritesScreen(),
    const Settings(),
  ];

  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, String>> _messages = [];
  final ApiService _apiService = ApiService();
  final AdsService _adsService = AdsService();
  bool _isLoading = false;
  int _previousIndex = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Show interstitial ad when changing tabs (with some logic to not show too frequently)
  Future<void> _maybeShowInterstitial(int newIndex) async {
    // Only show interstitial when navigating from dashboard to another tab,
    // and only one in every three times to reduce frequency
    if (_previousIndex == 0 && newIndex != 0 && DateTime.now().second % 3 == 0) {
      await _adsService.showInterstitialAd();
    }
    _previousIndex = currentIndex;
    setState(() {
      currentIndex = newIndex;
    });
  }

  void _toggleChat() {
    setState(() {
      _isChatOpen = !_isChatOpen;
      if (_isChatOpen) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  Future<void> _sendMessage(String userMessage) async {
    if (userMessage.isEmpty) return;

    setState(() {
      _messages.add({'sender': 'user', 'text': userMessage});
      _messageController.clear();
      _isLoading = true;
    });

    try {
      final response = await _apiService.getChatbotResponse(userMessage);
      setState(() {
        _messages.add({
          'sender': 'bot',
          'text': _formatBotResponse(response),
        });
      });
    } catch (e) {
      setState(() {
        _messages.add({
          'sender': 'bot',
          'text': 'Error: Unable to get response. Please try again.',
        });
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatBotResponse(String response) {
    response = response.replaceAllMapped(
        RegExp(r'\*\*(.*?)\*\*'), (match) => '<b>${match.group(1)}</b>');
    response = response.replaceAllMapped(
        RegExp(r'\*\s(.*)'), (match) => '<li>${match.group(1)}</li>');
    response = response.replaceAllMapped(
        RegExp(r'(<li>.*?</li>)'), (match) => '<ul>${match.group(0)}</ul>');
    response = response.replaceAll('\n', '<br>');
    return response;
  }

  Widget _buildChatOverlay() {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 1),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      )),
      child: Container(
        margin: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 10,
          bottom: 70,
          left: 10,
          right: 10
        ),
        height: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top - 90,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1E1E1E), Color(0xFF2D2D2D)],
          ),
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(25),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.red, Color(0xFF8B0000)],
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Movie Assistant',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: _toggleChat,
                    ),
                  ],
                ),
              ),
              if (_messages.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[850],
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Text(
                      'Hello! I can help you find movies, provide information about movies, actors, directors, and give personalized recommendations. How can I assist you today?',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final message = _messages[index];
                    return Align(
                      alignment: message['sender'] == 'user'
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                          vertical: 5,
                          horizontal: 10,
                        ),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: message['sender'] == 'user'
                                ? [Colors.red, const Color(0xFF8B0000)]
                                : [const Color(0xFF2D2D2D), const Color(0xFF1E1E1E)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: message['sender'] == 'bot'
                            ? Html(
                                data: message['text'] ?? '',
                                style: {"body": Style(color: Colors.white)},
                              )
                            : Text(
                                message['text'] ?? '',
                                style: const TextStyle(color: Colors.white),
                              ),
                      ),
                    );
                  },
                ),
              ),
              if (_isLoading)
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[850],
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.red,
                            strokeWidth: 2,
                          ),
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Thinking...',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFF1E1E1E),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[850],
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: TextField(
                          controller: _messageController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Ask about movies...',
                            hintStyle: TextStyle(color: Colors.grey[400]),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.red, Color(0xFF8B0000)],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.send, color: Colors.white),
                        onPressed: () => _sendMessage(_messageController.text),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          screens[currentIndex],
          if (_isChatOpen) _buildChatOverlay(),
          Positioned(
            bottom: 16,
            right: 16,
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.red, Color(0xFF8B0000)],
                ),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.3),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _toggleChat,
                  borderRadius: BorderRadius.circular(30),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Icon(
                      _isChatOpen ? Icons.close : Icons.chat,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Navigation Bar - Banner ad removed to improve user experience
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1E1E1E), Color(0xFF2D2D2D)],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: BottomNavigationBar(
                currentIndex: currentIndex,
                onTap: (index) {
                  _maybeShowInterstitial(index);
                },
                backgroundColor: Colors.transparent,
                selectedItemColor: Colors.red,
                unselectedItemColor: Colors.grey,
                type: BottomNavigationBarType.fixed,
                elevation: 0,
                items: [
                  _buildNavItem(Icons.home, "Dashboard", 0),
                  _buildNavItem(Icons.search, "Search", 1),
                  _buildNavItem(Icons.theater_comedy, "Cinemas", 2),
                  _buildNavItem(Icons.watch_later, "Watch Later", 3),
                  _buildNavItem(Icons.settings, "Settings", 4),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem(IconData icon, String label, int index) {
    return BottomNavigationBarItem(
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          gradient: currentIndex == index
              ? const LinearGradient(
                  colors: [Colors.red, Color(0xFF8B0000)],
                )
              : null,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Icon(icon),
      ),
      label: label,
    );
  }
}
