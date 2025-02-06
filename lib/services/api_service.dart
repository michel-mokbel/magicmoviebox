import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  Future<String> getChatbotResponse(String userMessage) async {
    const String apiKey = 'AIzaSyDSDbDdkatl9j_ewY2CiY5scURhh6Gdkbk';
    const String apiUrl =
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent?key=$apiKey';

    final payload = {
      "contents": [
        {
          "parts": [
            {"text": "You are a movie expert and recommendation system. Help users find movies, provide information about movies, actors, directors, and give personalized recommendations."},
            {
              "text": "$userMessage Please respond in a friendly and helpful manner."
            }
          ]
        }
      ],     
      "generationConfig": {
        "stopSequences": ["Title"],
        "temperature": 0.5,
        "maxOutputTokens": 200,
        "topP": 0.8,
        "topK": 10
      }
    };

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['candidates'][0]['content']['parts'][0]['text'] ?? 'No response available.';
      } else {
        return 'Unable to connect to the chatbot. Please try again later.';
      }
    } catch (e) {
      return 'Error: $e';
    }
  }

  Future<void> sendContactMessage(String name, String email, String message) async {
    // Implement your contact form submission logic here
    // For example, sending to a backend server or email service
    await Future.delayed(const Duration(seconds: 1)); // Simulated delay
    // You can add actual implementation later
  }
} 