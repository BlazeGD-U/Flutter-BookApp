import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../services/storage_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final StorageService _storageService = StorageService();
  final DatabaseService _databaseService = DatabaseService();

  UserModel? _user;
  bool _isLoading = false;
  String? _error;
  StreamSubscription<UserModel>? _userSubscription;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  AuthProvider() {
    _initAuthListener();
  }

  // Inicializar listener del estado de autenticación
  void _initAuthListener() {
    _authService.authStateChanges.listen((User? firebaseUser) async {
      if (firebaseUser != null) {
        await loadUserData();
      } else {
        _userSubscription?.cancel();
        _userSubscription = null;
        _user = null;
        notifyListeners();
      }
    });
  }

  // Cargar datos del usuario
  Future<void> loadUserData() async {
    try {
      _user = await _authService.getCurrentUserData();
      if (_user != null) {
        _listenToUserUpdates(_user!.id);
      }
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void _listenToUserUpdates(String userId) {
    _userSubscription?.cancel();
    _userSubscription = _databaseService.getUserStream(userId).listen(
      (user) {
        _user = user;
        notifyListeners();
      },
      onError: (error) {
        _error = error.toString();
        notifyListeners();
      },
    );
  }

  Future<void> refreshUserData() async {
    await loadUserData();
  }

  // Registro
  Future<bool> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _user = await _authService.signUp(
        name: name,
        email: email,
        password: password,
      );

      if (_user != null) {
        _listenToUserUpdates(_user!.id);
      }

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

  // Inicio de sesión
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _user = await _authService.signIn(
        email: email,
        password: password,
      );

      if (_user != null) {
        _listenToUserUpdates(_user!.id);
      }

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

  // Cerrar sesión
  Future<void> signOut() async {
    try {
      _userSubscription?.cancel();
      _userSubscription = null;
      await _authService.signOut();
      _user = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Actualizar perfil
  Future<bool> updateProfile({
    required String name,
    dynamic imageFile, // Puede ser File o Uint8List
  }) async {
    if (_user == null) return false;

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      String? photoUrl = _user!.photoUrl;

      // Subir nueva imagen si se proporciona
      if (imageFile != null) {
        photoUrl = await _storageService.uploadProfileImage(
          imageFile,
          _user!.id,
        );
      }

      await _authService.updateUserProfile(
        userId: _user!.id,
        name: name,
        photoUrl: photoUrl,
      );

      // Actualizar el usuario local
      _user = _user!.copyWith(
        name: name,
        photoUrl: photoUrl,
      );

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

  // Cambiar contraseña
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _authService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );

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
    _userSubscription?.cancel();
    super.dispose();
  }
}

