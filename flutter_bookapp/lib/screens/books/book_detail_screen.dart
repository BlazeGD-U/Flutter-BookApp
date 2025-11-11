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
  String? _currentImageUrl;

  @override
  void initState() {
    super.initState();
    _currentImageUrl = widget.book.imageUrl;
    if (_currentImageUrl != null && _currentImageUrl!.isNotEmpty) {
      _loadImage(_currentImageUrl!);
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
          _currentImageUrl = imageUrl;
        });
      }
    } catch (e) {
      print('Error cargando imagen detalle: $e');
    } finally {
      if (mounted) {
        setState(() => _loadingImage = false);
      }
    }
  }

  // Recargar imagen si cambió la URL
  void _checkAndReloadImage(String? newImageUrl) {
    if (newImageUrl != null && 
        newImageUrl.isNotEmpty && 
        newImageUrl != _currentImageUrl) {
      _imageData = null;
      _loadImage(newImageUrl);
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
      body: Consumer<BookProvider>(
        builder: (context, bookProvider, _) {
          // Buscar el libro actualizado desde el provider
          final updatedBook = bookProvider.books.firstWhere(
            (b) => b.id == widget.book.id,
            orElse: () => widget.book,
          );
          
          // Verificar si cambió la imagen y recargarla
          _checkAndReloadImage(updatedBook.imageUrl);
          
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Imagen del libro
                Container(
                  width: double.infinity,
                  height: 400,
                  color: AppConstants.secondaryColor,
                  child: updatedBook.imageUrl != null && updatedBook.imageUrl!.isNotEmpty
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
                        updatedBook.title,
                        style: Theme.of(context).textTheme.displayMedium,
                      ),
                      const SizedBox(height: 8),
                      
                      // Autor
                      Text(
                        'por ${updatedBook.author}',
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
                              updatedBook.category,
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
                              color: updatedBook.status == 'Leído'
                                  ? Colors.green.withOpacity(0.2)
                                  : Colors.orange.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              updatedBook.status,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: updatedBook.status == 'Leído'
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
                        updatedBook.description,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 32),
                      
                      // Botones de acción
                      Row(
                        children: [
                          Expanded(
                            child: CustomButton(
                              text: 'Editar',
                              onPressed: () async {
                                final userId = context.read<AuthProvider>().user?.id;
                                if (userId != null) {
                                  await Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => AddEditBookScreen(
                                        userId: userId,
                                        book: updatedBook,
                                      ),
                                    ),
                                  );
                                  // Después de editar, el Consumer se actualizará automáticamente
                                }
                              },
                              isOutlined: true,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: CustomButton(
                              text: 'Eliminar',
                              onPressed: () => _confirmDelete(context, updatedBook),
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
          );
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, BookModel book) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar libro'),
        content: Text('¿Estás seguro de que deseas eliminar "${book.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              
              final bookProvider = context.read<BookProvider>();
              final success = await bookProvider.deleteBook(book);
              
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

