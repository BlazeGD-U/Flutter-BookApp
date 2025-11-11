import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../models/book_model.dart';
import '../../providers/book_provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/custom_button.dart';
import 'add_edit_book_screen.dart';

class BookDetailScreen extends StatefulWidget {
  final BookModel book;

  const BookDetailScreen({
    super.key,
    required this.book,
  });

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  Uint8List? _imageData;
  bool _loadingImage = false;

  @override
  void initState() {
    super.initState();
    if (widget.book.imageUrl != null && widget.book.imageUrl!.isNotEmpty) {
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
      print('Error cargando imagen detalle: $e');
    } finally {
      setState(() => _loadingImage = false);
    }
  }

  Widget _buildImage() {
    if (_loadingImage) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_imageData != null) {
      return Image.memory(
        _imageData!,
        fit: BoxFit.contain,
      );
    }

    return const Icon(Icons.book, size: 100, color: Colors.grey);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalles del Libro'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen del libro
            Container(
              width: double.infinity,
              height: 400,
              color: AppConstants.secondaryColor,
              child: widget.book.imageUrl != null && widget.book.imageUrl!.isNotEmpty
                  ? _buildImage()
                  : const Icon(Icons.book, size: 100, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            
            // Información del libro
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título
                  Text(
                    widget.book.title,
                    style: Theme.of(context).textTheme.displayMedium,
                  ),
                  const SizedBox(height: 8),
                  
                  // Autor
                  Text(
                    'por ${widget.book.author}',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 16),
                  
                  // Categoría y Estado
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppConstants.primaryColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          widget.book.category,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppConstants.primaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: widget.book.status == 'Leído'
                              ? Colors.green.withOpacity(0.2)
                              : Colors.orange.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          widget.book.status,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: widget.book.status == 'Leído'
                                    ? Colors.green[700]
                                    : Colors.orange[700],
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Descripción
                  Text(
                    'Descripción',
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  const SizedBox(height: 12),
                  
                  Text(
                    widget.book.description,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 32),
                  
                  // Botones de acción
                  Row(
                    children: [
                      Expanded(
                        child: CustomButton(
                          text: 'Editar',
                          onPressed: () {
                            final userId = context.read<AuthProvider>().user?.id;
                            if (userId != null) {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => AddEditBookScreen(
                                    userId: userId,
                                    book: widget.book,
                                  ),
                                ),
                              );
                            }
                          },
                          isOutlined: true,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: CustomButton(
                          text: 'Eliminar',
                          onPressed: () => _confirmDelete(context),
                          backgroundColor: AppConstants.errorColor,
                          textColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar libro'),
        content: Text('¿Estás seguro de que deseas eliminar "${widget.book.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              
              final bookProvider = context.read<BookProvider>();
              final success = await bookProvider.deleteBook(widget.book);
              
              if (context.mounted) {
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Libro eliminado correctamente'),
                    ),
                  );
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(bookProvider.error ?? 'Error al eliminar el libro'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

