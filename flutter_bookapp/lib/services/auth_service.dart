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
      throw 'Error al crear la cuenta: ${e.toString()}';
    }
    return null;
  }

  Future<UserModel?> signIn({
    required String email,
    required String password,
  }) async {
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
      throw 'Error al iniciar sesión: ${e.toString()}';
    }
    return null;
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw 'Error al cerrar sesión: ${e.toString()}';
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
      throw 'Error al obtener datos del usuario: ${e.toString()}';
    }
    return null;
  }

  Future<void> updateUserProfile({
    required String userId,
    required String name,
    String? photoUrl,
  }) async {
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
      throw 'Error al actualizar el perfil: ${e.toString()}';
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
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
        throw 'La contraseña actual es incorrecta';
      }
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Error al cambiar la contraseña: ${e.toString()}';
    }
  }

  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No existe una cuenta con este correo electrónico';
      case 'wrong-password':
        return 'Contraseña incorrecta';
      case 'email-already-in-use':
        return 'Ya existe una cuenta con este correo electrónico';
      case 'invalid-email':
        return 'El correo electrónico no es válido';
      case 'weak-password':
        return 'La contraseña es muy débil';
      case 'user-disabled':
        return 'Esta cuenta ha sido deshabilitada';
      case 'too-many-requests':
        return 'Demasiados intentos. Intenta más tarde';
      case 'operation-not-allowed':
        return 'Operación no permitida';
      default:
        return 'Error de autenticación: ${e.message}';
    }
  }
}

