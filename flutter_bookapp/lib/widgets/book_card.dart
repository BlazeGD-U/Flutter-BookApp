import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../models/book_model.dart';
import '../providers/reading_session_provider.dart';
import '../utils/constants.dart';
import 'reading_timer_dialog.dart';

class BookCard extends StatefulWidget {
  final BookModel book;
  final VoidCallback onTap;

  const BookCard({
    super.key,
    required this.book,
    required this.onTap,
  });

  @override
  State<BookCard> createState() => _BookCardState();
}

class _BookCardState extends State<BookCard> {
  Uint8List? _imageData;
  bool _loadingImage = false;
  String? _currentImageUrl;

  @override
  void initState() {
    super.initState();
    _currentImageUrl = widget.book.imageUrl;
    if (kIsWeb && _currentImageUrl != null && _currentImageUrl!.isNotEmpty) {
      _loadImage(_currentImageUrl!);
    }
  }

  @override
  void didUpdateWidget(BookCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Si cambió la URL de la imagen, recargarla
    if (widget.book.imageUrl != _currentImageUrl) {
      _currentImageUrl = widget.book.imageUrl;
      _imageData = null;
      if (kIsWeb && _currentImageUrl != null && _currentImageUrl!.isNotEmpty) {
        _loadImage(_currentImageUrl!);
      }
    }
  }

  Future<void> _loadImage(String imageUrl) async {
    if (_loadingImage) return;
    
    setState(() => _loadingImage = true);
    
    try {
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200 && mounted) {
        setState(() {
          _imageData = response.bodyBytes;
        });
      }
    } catch (e) {
      print('Error cargando imagen: $e');
    } finally {
      if (mounted) {
        setState(() => _loadingImage = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Imagen del libro
              Container(
                width: 60,
                height: 80,
                decoration: BoxDecoration(
                  color: AppConstants.secondaryColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: widget.book.imageUrl != null && widget.book.imageUrl!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: _buildImage(),
                      )
                    : const Icon(Icons.book, size: 30, color: Colors.grey),
              ),
              const SizedBox(width: 12),
              // Información del libro
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.book.title,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.book.author,
                      style: Theme.of(context).textTheme.bodyMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Tiempo de lectura',
                    onPressed: () => _startReadingTimer(context),
                    icon: const Icon(Icons.timer_outlined),
                    color: AppConstants.primaryColor,
                  ),
                  _PointsBadge(points: widget.book.readingPoints),
                ],
              ),
              Icon(
                Icons.chevron_right,
                color: AppConstants.textSecondaryColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _startReadingTimer(BuildContext context) async {
    final session = context.read<ReadingSessionProvider>();
    if (session.isActive) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ya tienes una sesión de lectura activa'),
        ),
      );
      return;
    }

    final duration = await showDialog<Duration>(
      context: context,
      builder: (_) => const ReadingTimerDialog(),
    );

    if (duration != null && context.mounted) {
      session.startSession(widget.book, duration);
    }
  }

  Widget _buildImage() {
    if (_loadingImage) {
      return const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    if (_imageData != null) {
      return Image.memory(
        _imageData!,
        fit: BoxFit.cover,
      );
    }

    // En web, mostrar ícono en lugar de intentar cargar
    if (kIsWeb) {
      return const Icon(Icons.book, size: 30, color: Colors.grey);
    }

    return const Icon(Icons.book, size: 30, color: Colors.grey);
  }
}

class _PointsBadge extends StatelessWidget {
  final int points;

  const _PointsBadge({required this.points});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Puntos de este libro',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppConstants.primaryColor.withOpacity(0.25),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.stars_rounded,
              size: 16,
              color: AppConstants.primaryColor,
            ),
            const SizedBox(width: 4),
            Text(
              '$points',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppConstants.textPrimaryColor,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

