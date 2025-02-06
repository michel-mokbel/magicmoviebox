import 'package:flutter/material.dart';
import 'package:moviemagicbox/screens/search_screen.dart';
import 'package:moviemagicbox/screens/settings_screen.dart';
import 'package:moviemagicbox/screens/favorites_screen.dart';
import 'package:flutter_html/flutter_html.dart';
import '../services/api_service.dart';
import 'dashboard_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int currentIndex = 0;
  bool _isChatOpen = false;
  final List<Widget> screens = [
    const DashboardScreen(),
    const SearchScreen(),
    const FavoritesScreen(),
    const Settings(),
  ];

  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, String>> _messages = [];
  final ApiService _apiService = ApiService();
  bool _isLoading = false;

  void _toggleChat() {
    setState(() {
      _isChatOpen = !_isChatOpen;
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
    return Positioned(
      bottom: 70,
      right: 10,
      left: 10,
      child: Container(
        height: 600,
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey.shade800),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    'Chat with Movie Assistant',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: _toggleChat,
                ),
              ],
            ),
            const Divider(color: Colors.red),
            if (_messages.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Hello! I can help you find movies, provide information about movies, actors, directors, and give personalized recommendations. How can I assist you today?',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(8.0),
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
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: message['sender'] == 'user'
                            ? Colors.red
                            : Colors.grey[800],
                        borderRadius: BorderRadius.circular(10),
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
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: CircularProgressIndicator(color: Colors.red),
              ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Ask about movies...',
                        hintStyle: TextStyle(color: Colors.grey),
                        border: OutlineInputBorder(),
                        fillColor: Color.fromARGB(255, 30, 30, 30),
                        filled: true,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send, color: Colors.red),
                    onPressed: () => _sendMessage(_messageController.text),
                  ),
                ],
              ),
            ),
          ],
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
            bottom: 10,
            right: 10,
            child: FloatingActionButton(
              onPressed: _toggleChat,
              backgroundColor: Colors.red,
              child: Icon(
                _isChatOpen ? Icons.close : Icons.chat,
                color: Colors.white
              ),
            ),
          ),
        ],
      ),
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
