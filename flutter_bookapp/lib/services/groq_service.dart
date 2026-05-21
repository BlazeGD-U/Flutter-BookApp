import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/ai_recommendation.dart';

class GroqService {
  Future<String> _chatCompletion({
    required String systemPrompt,
    required String userPrompt,
  }) async {
    if (!AppConfig.isGroqConfigured) {
      throw 'Configura tu API key de Groq en el archivo .env (GROQ_API_KEY)';
    }

    final response = await http.post(
      Uri.parse('${AppConfig.groqBaseUrl}/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${AppConfig.groqApiKey}',
      },
      body: jsonEncode({
        'model': AppConfig.groqModel,
        'messages': [
          {'role': 'system', 'content': systemPrompt},
          {'role': 'user', 'content': userPrompt},
        ],
        'temperature': 0.7,
        'max_tokens': 1024,
      }),
    );

    if (response.statusCode != 200) {
      final errorBody = response.body;
      throw 'Error de Groq (${response.statusCode}): $errorBody';
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final choices = data['choices'] as List<dynamic>?;
    if (choices == null || choices.isEmpty) {
      throw 'Groq no devolvió una respuesta válida';
    }

    final content = choices.first['message']?['content'] as String?;
    if (content == null || content.trim().isEmpty) {
      throw 'Respuesta vacía de Groq';
    }

    return content.trim();
  }

  String _extractJson(String raw) {
    var text = raw.trim();
    if (text.startsWith('```')) {
      text = text.replaceFirst(RegExp(r'^```(?:json)?\s*'), '');
      text = text.replaceFirst(RegExp(r'\s*```$'), '');
    }
    final start = text.indexOf('{');
    final end = text.lastIndexOf('}');
    if (start >= 0 && end > start) {
      return text.substring(start, end + 1);
    }
    return text;
  }

  Future<AiBookRecommendation> getDiscoverRecommendation({
    required String genre,
    required String favoriteAuthor,
    required String averagePages,
    required String freeHoursPerDay,
  }) async {
    const systemPrompt = '''
Eres un bibliotecario experto en recomendar libros en español.
Responde ÚNICAMENTE con un JSON válido (sin markdown) con esta estructura exacta:
{
  "title": "título del libro",
  "author": "autor",
  "category": "género/categoría",
  "description": "descripción de 3 a 5 oraciones explicando por qué encaja con el lector"
}
''';

    final userPrompt = '''
Recomienda UN libro específico y real basado en:
- Género favorito: $genre
- Autor que le gusta en ese género: $favoriteAuthor
- Páginas que lee en promedio: $averagePages
- Horas libres al día para leer: $freeHoursPerDay
''';

    final raw = await _chatCompletion(
      systemPrompt: systemPrompt,
      userPrompt: userPrompt,
    );

    try {
      final json = jsonDecode(_extractJson(raw)) as Map<String, dynamic>;
      return AiBookRecommendation.fromJson(json);
    } catch (_) {
      throw 'No se pudo interpretar la recomendación de Groq';
    }
  }

  Future<String> getMediaRecommendations({
    required String title,
    required String author,
    required String category,
    required String description,
  }) async {
    const systemPrompt = '''
Eres un experto en cine y series. Respondes en español de forma clara y amigable.
Lista 4 a 6 películas o series relacionadas con el libro (adaptaciones, mismo género o temática).
Usa viñetas con guión (-). No uses JSON.
''';

    final userPrompt = '''
Libro: "$title" de $author
Categoría: $category
Descripción: $description

Recomienda películas y series que podrían interesar a alguien que disfrutó este libro.
''';

    return _chatCompletion(
      systemPrompt: systemPrompt,
      userPrompt: userPrompt,
    );
  }
}
