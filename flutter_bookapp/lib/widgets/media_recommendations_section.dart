import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../models/book_model.dart';
import '../services/groq_service.dart';
import '../utils/constants.dart';

class MediaRecommendationsSection extends StatefulWidget {
  final BookModel book;

  const MediaRecommendationsSection({
    super.key,
    required this.book,
  });

  @override
  State<MediaRecommendationsSection> createState() =>
      _MediaRecommendationsSectionState();
}

class _MediaRecommendationsSectionState
    extends State<MediaRecommendationsSection> {
  final _groqService = GroqService();
  String? _content;
  String? _error;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
  }

  Future<void> _loadRecommendations() async {
    if (!AppConfig.isGroqConfigured) {
      setState(() {
        _error = 'Configura GROQ_API_KEY en .env para ver recomendaciones';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await _groqService.getMediaRecommendations(
        title: widget.book.title,
        author: widget.book.author,
        category: widget.book.category,
        description: widget.book.description,
      );

      if (!mounted) return;
      setState(() {
        _content = result;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.movie_filter_outlined,
              color: AppConstants.primaryColor,
            ),
            const SizedBox(width: 8),
            Text(
              'Series y películas relacionadas',
              style: Theme.of(context).textTheme.displaySmall,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Generado con IA según tu libro',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 16),
        if (_isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_error != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppConstants.secondaryColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _error!,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: _loadRecommendations,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reintentar'),
                ),
              ],
            ),
          )
        else if (_content != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppConstants.whiteColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppConstants.primaryColor.withOpacity(0.3),
              ),
            ),
            child: Text(
              _content!,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
      ],
    );
  }
}
