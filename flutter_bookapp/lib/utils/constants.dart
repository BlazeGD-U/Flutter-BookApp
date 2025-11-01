import 'package:flutter/material.dart';

class AppConstants {
  // Colores de la aplicación (basados en los mockups)
  static const Color primaryColor = Color(0xFF9FCDE8); // Azul claro
  static const Color secondaryColor = Color(0xFFE8E9EB); // Gris claro
  static const Color backgroundColor = Color(0xFFF5F6F8);
  static const Color textPrimaryColor = Color(0xFF1A1A1A);
  static const Color textSecondaryColor = Color(0xFF6B7280);
  static const Color errorColor = Color(0xFFEF4444);
  static const Color whiteColor = Color(0xFFFFFFFF);
  
  // Categorías de libros
  static const List<String> categories = [
    'Fantasía',
    'Ciencia Ficción',
    'Romance',
    'Thriller',
    'Misterio',
    'No Ficción',
    'Biografía',
    'Historia',
    'Autoayuda',
    'Psychological Thriller',
    'Otro',
  ];
  
  // Estados de libros
  static const List<String> bookStatus = [
    'Pendiente',
    'Leído',
  ];
  
  // Mensajes de notificación para libros pendientes
  static const List<String> notificationMessages = [
    'Es hora de continuar con "{title}". ¡No pierdas el ritmo!',
    'Oye, he visto que "{title}" no lo has tocado. Es hora de una lectura, ¿no crees?',
    '"{title}" te espera. ¡Sumérgete en Arrakis!',
    '¿Qué tal un capítulo de "{title}" hoy?',
    'Recordatorio de lectura: "{title}" está esperando por ti.',
    '¡No olvides continuar con "{title}"!',
  ];
  
  // Rutas de Firebase Realtime Database
  static const String usersPath = 'users';
  static const String booksPath = 'books';
  static const String recommendationsPath = 'recommendations';
  static const String notificationsPath = 'notifications';
  
  // Límites
  static const int maxImageSizeBytes = 5 * 1024 * 1024; // 5MB
  static const int daysUntilNotification = 5;
}

