import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../models/book_model.dart';
import '../utils/constants.dart';

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

  @override
  void initState() {
    super.initState();
    if (kIsWeb && widget.book.imageUrl != null && widget.book.imageUrl!.isNotEmpty) {
      _loadImage();
    }
  }

  Future<void> _loadImage() async {
    if (_loadingImage || _imageData != null) return;
    
    setState(() => _loadingImage = true);
    
    try {
      final response = await http.get(Uri.parse(widget.book.imageUrl!));
      if (response.statusCode == 200) {
        setState(() {
          _imageData = response.bodyBytes;
        });
      }
    } catch (e) {
      print('Error cargando imagen: $e');
    } finally {
      setState(() => _loadingImage = false);
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
              // Icono de navegación
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

