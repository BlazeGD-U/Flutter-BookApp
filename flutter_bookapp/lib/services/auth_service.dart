import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserModel?> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    // Validaciones previas con mensajes claros y amables
    final nameError = _validateName(name);
    if (nameError != null) throw nameError;

    final emailError = _validateEmail(email);
    if (emailError != null) throw emailError;

    final pwdError = _validatePassword(password);
    if (pwdError != null) throw pwdError;

    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        final user = UserModel(
          id: userCredential.user!.uid,
          name: name,
          email: email,
          createdAt: DateTime.now(),
        );

        await _database
            .child(AppConstants.usersPath)
            .child(user.id)
            .set(user.toMap());

        await userCredential.user!.updateDisplayName(name);

        return user;
      }
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'No pudimos crear tu cuenta en este momento: ${e.toString()}';
    }
    return null;
  }

  Future<UserModel?> signIn({
    required String email,
    required String password,
  }) async {
    // Validaciones previas para feedback inmediato
    final emailError = _validateEmail(email);
    if (emailError != null) throw emailError;

    if (password.isEmpty) throw 'Por favor, ingresa tu contraseña';

    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        final snapshot = await _database
            .child(AppConstants.usersPath)
            .child(userCredential.user!.uid)
            .get();

        if (snapshot.exists) {
          return UserModel.fromMap(
            snapshot.value as Map<dynamic, dynamic>,
            userCredential.user!.uid,
          );
        } else {
          // Si no existe el usuario en la base de datos, crear uno por defecto
          final user = UserModel(
            id: userCredential.user!.uid,
            name: userCredential.user!.displayName ?? 'Usuario',
            email: email,
            createdAt: DateTime.now(),
          );

          await _database
              .child(AppConstants.usersPath)
              .child(user.id)
              .set(user.toMap());

          return user;
        }
      }
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'No pudimos iniciar sesión en este momento: ${e.toString()}';
    }
    return null;
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw 'No fue posible cerrar sesión: ${e.toString()}';
    }
  }

  Future<UserModel?> getCurrentUserData() async {
    try {
      final user = currentUser;
      if (user != null) {
        final snapshot = await _database
            .child(AppConstants.usersPath)
            .child(user.uid)
            .get();

        if (snapshot.exists) {
          return UserModel.fromMap(
            snapshot.value as Map<dynamic, dynamic>,
            user.uid,
          );
        }
      }
    } catch (e) {
      throw 'No pudimos obtener tus datos: ${e.toString()}';
    }
    return null;
  }

  Future<void> updateUserProfile({
    required String userId,
    required String name,
    String? photoUrl,
  }) async {
    final nameError = _validateName(name);
    if (nameError != null) throw nameError;

    try {
      final updates = {
        'name': name,
        if (photoUrl != null) 'photoUrl': photoUrl,
      };

      await _database
          .child(AppConstants.usersPath)
          .child(userId)
          .update(updates);

      await currentUser?.updateDisplayName(name);

      if (photoUrl != null) {
        await currentUser?.updatePhotoURL(photoUrl);
      }
    } catch (e) {
      throw 'No fue posible actualizar tu perfil: ${e.toString()}';
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final pwdError = _validatePassword(newPassword);
    if (pwdError != null) throw pwdError;

    try {
      final user = currentUser;
      if (user == null || user.email == null) {
        throw 'No hay usuario autenticado';
      }

      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password') {
        throw 'La contraseña actual no coincide. ¿Quieres intentarlo de nuevo?';
      }
      throw _handleAuthException(e);
    } catch (e) {
      throw 'No pudimos cambiar tu contraseña: ${e.toString()}';
    }
  }

  String _handleAuthException(FirebaseAuthException e) {
    // Mensajes más amables y útiles para el usuario
    switch (e.code) {
      case 'user-not-found':
        return 'No encontramos una cuenta con ese correo. ¿Quieres crear una?';
      case 'wrong-password':
        return 'La contraseña no coincide. ¿Quieres intentarlo otra vez?';
      case 'email-already-in-use':
        return 'Ese correo ya está registrado. ¿Quieres iniciar sesión?';
      case 'invalid-email':
        return 'Parece que el correo tiene un formato incorrecto. ¿Puedes revisarlo?';
      case 'weak-password':
        return 'La contraseña es muy débil. Prueba con letras y números, mínimo 6 caracteres.';
      case 'user-disabled':
        return 'Esta cuenta ha sido deshabilitada. Si crees que es un error, contáctanos.';
      case 'too-many-requests':
        return 'Hemos recibido muchos intentos. Toma un respiro y vuelve a intentarlo más tarde.';
      case 'operation-not-allowed':
        return 'Esta opción no está habilitada en este momento.';
      default:
        return 'Error de autenticación: ${e.message ?? 'algo salió mal'}';
    }
  }

  // ----------------- Helpers de validación locales -----------------

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Por favor, ingresa tu correo electrónico';
    }

    if (value.contains(' ')) {
      return 'El correo no puede tener espacios. Por favor, revisa tu correo';
    }

    if (!value.contains('@')) {
      return 'Parece que falta el símbolo "@" en tu correo. ¿Puedes revisarlo?';
    }

    final parts = value.split('@');
    if (parts.length != 2 || parts[1].isEmpty) {
      return 'Por favor, revisa tu correo: falta el dominio después del @';
    }

    if (!parts[1].contains('.')) {
      return 'Por favor, revisa tu correo: falta el dominio completo (ejemplo: gmail.com)';
    }

    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Por favor, revisa tu correo: el formato no es válido';
    }

    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor, ingresa tu contraseña';
    }

    if (value.length < 6) {
      return 'Tu contraseña debe tener al menos 6 caracteres para mayor seguridad';
    }

    if (value.length > 50) {
      return 'Tu contraseña es demasiado larga. Máximo 50 caracteres';
    }

    // Requerir al menos una letra y un número
    final pattern = RegExp(r'^(?=.*[A-Za-z])(?=.*\d).+$');
    if (!pattern.hasMatch(value)) {
      return 'Para mayor seguridad, usa una contraseña que combine letras y números';
    }

    return null;
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Por favor, ingresa tu nombre';
    }

    if (value.trim().length < 2) {
      return 'Tu nombre debe tener al menos 2 caracteres';
    }

    if (value.trim().length > 50) {
      return 'Tu nombre es demasiado largo. Máximo 50 caracteres';
    }

    if (RegExp(r'^\d+$').hasMatch(value.trim())) {
      return 'Por favor, ingresa un nombre válido (no solo números)';
    }

    if (!RegExp(r'^[A-Za-zÁÉÍÓÚáéíóúÑñ\s]+$').hasMatch(value.trim())) {
      return 'El nombre solo puede contener letras y espacios';
    }

    return null;
  }
}

