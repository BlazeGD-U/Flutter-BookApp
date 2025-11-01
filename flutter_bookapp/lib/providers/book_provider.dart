import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/book_model.dart';
import '../services/database_service.dart';
import '../services/storage_service.dart';

class BookProvider with ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  final StorageService _storageService = StorageService();

  List<BookModel> _books = [];
  List<BookModel> _filteredBooks = [];
  List<BookModel> _recommendations = [];
  
  bool _isLoading = false;
  String? _error;
  
  String _searchQuery = '';
  String? _categoryFilter;
  String? _statusFilter;

  StreamSubscription? _booksSubscription;
  StreamSubscription? _recommendationsSubscription;

  List<BookModel> get books => _filteredBooks;
  List<BookModel> get recommendations => _recommendations;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  String? get categoryFilter => _categoryFilter;
  String? get statusFilter => _statusFilter;

  // Inicializar streams para el usuario
  void initializeStreams(String userId) {
    // Stream de libros del usuario
    _booksSubscription = _databaseService.getUserBooks(userId).listen(
      (books) {
        _books = books;
        _applyFilters();
        notifyListeners();
      },
      onError: (error) {
        _error = error.toString();
        notifyListeners();
      },
    );

    // Stream de recomendaciones
    _recommendationsSubscription = _databaseService.getRecommendations().listen(
      (recommendations) {
        _recommendations = recommendations;
        notifyListeners();
      },
      onError: (error) {
        _error = error.toString();
        notifyListeners();
      },
    );
  }

  // Aplicar filtros
  void _applyFilters() {
    _filteredBooks = _books.where((book) {
      // Filtro de búsqueda
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        if (!book.title.toLowerCase().contains(query) &&
            !book.author.toLowerCase().contains(query)) {
          return false;
        }
      }

      // Filtro de categoría
      if (_categoryFilter != null && book.category != _categoryFilter) {
        return false;
      }

      // Filtro de estado
      if (_statusFilter != null && book.status != _statusFilter) {
        return false;
      }

      return true;
    }).toList();
  }

  // Establecer búsqueda
  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  // Establecer filtro de categoría
  void setCategoryFilter(String? category) {
    _categoryFilter = category;
    _applyFilters();
    notifyListeners();
  }

  // Establecer filtro de estado
  void setStatusFilter(String? status) {
    _statusFilter = status;
    _applyFilters();
    notifyListeners();
  }

  // Limpiar filtros
  void clearFilters() {
    _searchQuery = '';
    _categoryFilter = null;
    _statusFilter = null;
    _applyFilters();
    notifyListeners();
  }

  // Agregar libro
  Future<bool> addBook({
    required String userId,
    required String title,
    required String author,
    required String category,
    required String status,
    required String description,
    File? imageFile,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      String? imageUrl;
      if (imageFile != null) {
        imageUrl = await _storageService.uploadBookImage(imageFile);
      }

      final book = BookModel(
        id: '',
        userId: userId,
        title: title,
        author: author,
        category: category,
        status: status,
        description: description,
        imageUrl: imageUrl,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _databaseService.addBook(book);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Actualizar libro
  Future<bool> updateBook({
    required BookModel book,
    required String title,
    required String author,
    required String category,
    required String status,
    required String description,
    File? imageFile,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      String? imageUrl = book.imageUrl;

      // Si hay nueva imagen, subir y eliminar la anterior
      if (imageFile != null) {
        imageUrl = await _storageService.uploadBookImage(imageFile);
        
        // Eliminar imagen anterior si existe
        if (book.imageUrl != null) {
          await _storageService.deleteImage(book.imageUrl!);
        }
      }

      final updatedBook = book.copyWith(
        title: title,
        author: author,
        category: category,
        status: status,
        description: description,
        imageUrl: imageUrl,
      );

      await _databaseService.updateBook(updatedBook);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Eliminar libro
  Future<bool> deleteBook(BookModel book) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Eliminar imagen si existe
      if (book.imageUrl != null) {
        await _storageService.deleteImage(book.imageUrl!);
      }

      await _databaseService.deleteBook(book.id);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Limpiar error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _booksSubscription?.cancel();
    _recommendationsSubscription?.cancel();
    super.dispose();
  }
}

