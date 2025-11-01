import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/notification_model.dart';
import '../services/database_service.dart';

class NotificationProvider with ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();

  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  String? _error;

  StreamSubscription? _notificationsSubscription;

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  int get unreadCount => _notifications.where((n) => !n.read).length;
  bool get hasUnread => unreadCount > 0;

  // Inicializar stream de notificaciones
  void initializeStream(String userId) {
    _notificationsSubscription = _databaseService
        .getUserNotifications(userId)
        .listen(
      (notifications) {
        _notifications = notifications;
        notifyListeners();
      },
      onError: (error) {
        _error = error.toString();
        notifyListeners();
      },
    );
  }

  // Marcar notificación como leída
  Future<void> markAsRead(String notificationId) async {
    try {
      await _databaseService.markNotificationAsRead(notificationId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Verificar y crear notificaciones para libros pendientes
  Future<void> checkPendingBooks(String userId) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _databaseService.checkAndCreateNotifications(userId);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Limpiar error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _notificationsSubscription?.cancel();
    super.dispose();
  }
}

