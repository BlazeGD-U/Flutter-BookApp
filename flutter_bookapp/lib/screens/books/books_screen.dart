import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/book_provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/book_card.dart';
import 'book_detail_screen.dart';
import 'add_edit_book_screen.dart';

class BooksScreen extends StatelessWidget {
  const BooksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MyBooks'),
      ),
      body: Column(
        children: [
          // Barra de búsqueda
          Padding(
            padding: const EdgeInsets.all(16),
            child: Consumer<BookProvider>(
              builder: (context, bookProvider, _) {
                return TextField(
                  decoration: InputDecoration(
                    hintText: 'Buscar libros',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: bookProvider.searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              bookProvider.setSearchQuery('');
                            },
                          )
                        : null,
                  ),
                  onChanged: (value) {
                    bookProvider.setSearchQuery(value);
                  },
                );
              },
            ),
          ),
          
          // Filtros
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Consumer<BookProvider>(
              builder: (context, bookProvider, _) {
                return Row(
                  children: [
                    // Filtro de categoría
                    _FilterChip(
                      label: 'Categoría',
                      selected: bookProvider.categoryFilter != null,
                      onTap: () => _showCategoryFilter(context, bookProvider),
                    ),
                    const SizedBox(width: 8),
                    
                    // Filtro de estado
                    _FilterChip(
                      label: 'Estado',
                      selected: bookProvider.statusFilter != null,
                      onTap: () => _showStatusFilter(context, bookProvider),
                    ),
                    const SizedBox(width: 8),
                    
                    // Limpiar filtros
                    if (bookProvider.categoryFilter != null ||
                        bookProvider.statusFilter != null)
                      TextButton.icon(
                        icon: const Icon(Icons.clear_all),
                        label: const Text('Limpiar'),
                        onPressed: () {
                          bookProvider.clearFilters();
                        },
                      ),
                  ],
                );
              },
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Lista de libros
          Expanded(
            child: Consumer<BookProvider>(
              builder: (context, bookProvider, _) {
                final books = bookProvider.books;

                if (books.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.book_outlined, size: 80, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text(
                          'No tienes libros agregados',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text('Agregar libro'),
                          onPressed: () {
                            _navigateToAddBook(context);
                          },
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: books.length,
                  itemBuilder: (context, index) {
                    final book = books[index];
                    return BookCard(
                      book: book,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => BookDetailScreen(book: book),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _navigateToAddBook(context);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _navigateToAddBook(BuildContext context) {
    final userId = context.read<AuthProvider>().user?.id;
    if (userId != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => AddEditBookScreen(userId: userId),
        ),
      );
    }
  }

  void _showCategoryFilter(BuildContext context, BookProvider bookProvider) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Seleccionar categoría',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: AppConstants.categories.length,
                itemBuilder: (context, index) {
                  final category = AppConstants.categories[index];
                  return ListTile(
                    title: Text(category),
                    trailing: bookProvider.categoryFilter == category
                        ? const Icon(Icons.check, color: Colors.blue)
                        : null,
                    onTap: () {
                      bookProvider.setCategoryFilter(category);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showStatusFilter(BuildContext context, BookProvider bookProvider) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Seleccionar estado',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(height: 1),
            ...AppConstants.bookStatus.map((status) {
              return ListTile(
                title: Text(status),
                trailing: bookProvider.statusFilter == status
                    ? const Icon(Icons.check, color: Colors.blue)
                    : null,
                onTap: () {
                  bookProvider.setStatusFilter(status);
                  Navigator.pop(context);
                },
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppConstants.primaryColor.withOpacity(0.3),
    );
  }
}

