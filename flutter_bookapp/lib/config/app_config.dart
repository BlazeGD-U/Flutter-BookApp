import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static const String groqBaseUrl = 'https://api.groq.com/openai/v1';
  static const String groqModel = 'llama-3.3-70b-versatile';

  static String get groqApiKey => dotenv.env['GROQ_API_KEY']?.trim() ?? '';

  static bool get isGroqConfigured => groqApiKey.isNotEmpty;
}
