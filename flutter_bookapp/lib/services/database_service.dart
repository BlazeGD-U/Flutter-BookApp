import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:uuid/uuid.dart';
import '../models/book_model.dart';
import '../models/notification_model.dart';
import '../utils/constants.dart';

class DatabaseService {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final Uuid _uuid = const Uuid();

  Future<String> addBook(BookModel book) async {
    try {
      final bookId = _uuid.v4();
      final bookWithId = book.copyWith(id: bookId);
      
      await _database
          .child(AppConstants.booksPath)
          .child(bookId)
          .set(bookWithId.toMap());
      
      return bookId;
    } catch (e) {
      throw 'Error al agregar el libro: ${e.toString()}';
    }
  }

  Future<void> updateBook(BookModel book) async {
    try {
      final updatedBook = book.copyWith(updatedAt: DateTime.now());
      
      await _database
          .child(AppConstants.booksPath)
          .child(book.id)
          .update(updatedBook.toMap());
    } catch (e) {
      throw 'Error al actualizar el libro: ${e.toString()}';
    }
  }

  Future<void> deleteBook(String bookId) async {
    try {
      await _database
          .child(AppConstants.booksPath)
          .child(bookId)
          .remove();
    } catch (e) {
      throw 'Error al eliminar el libro: ${e.toString()}';
    }
  }

  Stream<List<BookModel>> getUserBooks(String userId) {
    return _database
        .child(AppConstants.booksPath)
        .orderByChild('userId')
        .equalTo(userId)
        .onValue
        .map((event) {
      final books = <BookModel>[];
      
      if (event.snapshot.value != null) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        
        data.forEach((key, value) {
          books.add(BookModel.fromMap(
            Map<String, dynamic>.from(value as Map),
            key,
          ));
        });
      }
      
      books.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      
      return books;
    });
  }

  Future<BookModel?> getBook(String bookId) async {
    try {
      final snapshot = await _database
          .child(AppConstants.booksPath)
          .child(bookId)
          .get();

      if (snapshot.exists) {
        return BookModel.fromMap(
          snapshot.value as Map<dynamic, dynamic>,
          bookId,
        );
      }
    } catch (e) {
      throw 'Error al obtener el libro: ${e.toString()}';
    }
    return null;
  }

  Stream<List<BookModel>> getRecommendations() {
    return _database
        .child(AppConstants.recommendationsPath)
        .onValue
        .map((event) {
      final recommendations = <BookModel>[];
      
      if (event.snapshot.value != null) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        
        data.forEach((key, value) {
          final bookData = Map<String, dynamic>.from(value as Map);
          bookData['userId'] = '';
          
          recommendations.add(BookModel.fromMap(bookData, key));
        });
      }
      
      return recommendations;
    });
  }

  Future<void> createNotification({
    required String userId,
    required String bookId,
    required String bookTitle,
    required String message,
  }) async {
    try {
      final notificationId = _uuid.v4();
      final notification = NotificationModel(
        id: notificationId,
        userId: userId,
        bookId: bookId,
        bookTitle: bookTitle,
        message: message,
        createdAt: DateTime.now(),
      );

      await _database
          .child(AppConstants.notificationsPath)
          .child(notificationId)
          .set(notification.toMap());
    } catch (e) {
      throw 'Error al crear la notificación: ${e.toString()}';
    }
  }

  Stream<List<NotificationModel>> getUserNotifications(String userId) {
    return _database
        .child(AppConstants.notificationsPath)
        .orderByChild('userId')
        .equalTo(userId)
        .onValue
        .map((event) {
      final notifications = <NotificationModel>[];
      
      if (event.snapshot.value != null) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        
        data.forEach((key, value) {
          notifications.add(NotificationModel.fromMap(
            Map<String, dynamic>.from(value as Map),
            key,
          ));
        });
      }
      
      notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      return notifications;
    });
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _database
          .child(AppConstants.notificationsPath)
          .child(notificationId)
          .update({'read': true});
    } catch (e) {
      throw 'Error al marcar la notificación: ${e.toString()}';
    }
  }

  Future<void> checkAndCreateNotifications(String userId) async {
    try {
      print('🔍 [NOTIFICACIONES] Verificando notificaciones para usuario: $userId');
      
      final snapshot = await _database
          .child(AppConstants.booksPath)
          .orderByChild('userId')
          .equalTo(userId)
          .get();

      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        print('📚 [NOTIFICACIONES] Encontrados ${data.length} libros del usuario');
        
        for (var entry in data.entries) {
          final book = BookModel.fromMap(
            Map<String, dynamic>.from(entry.value as Map),
            entry.key,
          );

          print('📖 [NOTIFICACIONES] Verificando libro: "${book.title}" - Status: ${book.status}');

          if (book.isPendingForTooLong()) {
            print('⏰ [NOTIFICACIONES] Libro "${book.title}" está pendiente por demasiado tiempo');
            
            final notificationsSnapshot = await _database
                .child(AppConstants.notificationsPath)
                .orderByChild('bookId')
                .equalTo(book.id)
                .limitToLast(1)
                .get();

            bool shouldCreateNotification = true;

            if (notificationsSnapshot.exists) {
              final notificationData = Map<String, dynamic>.from(
                notificationsSnapshot.value as Map,
              );
              
              if (notificationData.isNotEmpty) {
                final lastNotification = NotificationModel.fromMap(
                  Map<String, dynamic>.from(
                    notificationData.values.first as Map,
                  ),
                  notificationData.keys.first,
                );

                // Para pruebas: verificar cada 2 minutos en lugar de 48 horas
                final minutesSinceLastNotification = 
                    DateTime.now().difference(lastNotification.createdAt).inMinutes;
                
                print('⏳ [NOTIFICACIONES] Última notificación hace: $minutesSinceLastNotification minutos');
                
                if (minutesSinceLastNotification < 2) {  // Cambiar a 120 para 2 horas, 2880 para 2 días
                  shouldCreateNotification = false;
                  print('❌ [NOTIFICACIONES] Esperando 2 minutos antes de crear nueva notificación');
                }
              }
            }
            
            if (shouldCreateNotification) {
              final random = DateTime.now().millisecondsSinceEpoch % 
                  AppConstants.notificationMessages.length;
              final message = AppConstants.notificationMessages[random]
                  .replaceAll('{title}', book.title);

              print('✅ [NOTIFICACIONES] Creando notificación para "${book.title}": $message');
              
              await createNotification(
                userId: userId,
                bookId: book.id,
                bookTitle: book.title,
                message: message,
              );
            }
          } else {
            final minutesDiff = DateTime.now().difference(book.updatedAt).inMinutes;
            print('⏸️ [NOTIFICACIONES] Libro "${book.title}" no está pendiente suficientemente (solo $minutesDiff minutos)');
          }
        }
      } else {
        print('📭 [NOTIFICACIONES] No se encontraron libros para el usuario');
      }
    } catch (e) {
      print('❌ [NOTIFICACIONES] Error: ${e.toString()}');
      throw 'Error al verificar notificaciones: ${e.toString()}';
    }
  }
}

