import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Uuid _uuid = const Uuid();

  Future<String> uploadProfileImage(dynamic imageFile, String userId) async {
    try {
      final fileName = 'profile_$userId.jpg';
      final ref = _storage.ref().child('profile_images').child(userId).child(fileName);
      
      UploadTask uploadTask;
      if (imageFile is Uint8List) {
        // Para web o cuando se pasa Uint8List directamente
        uploadTask = ref.putData(
          imageFile,
          SettableMetadata(contentType: 'image/jpeg'),
        );
      } else if (imageFile is File) {
        // Para mobile o cuando se pasa File
        uploadTask = ref.putFile(
          imageFile,
          SettableMetadata(contentType: 'image/jpeg'),
        );
      } else {
        throw 'Tipo de archivo no válido: ${imageFile.runtimeType}';
      }
      
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      throw 'Error al subir la imagen de perfil: ${e.toString()}';
    }
  }

  Future<String> uploadBookImage(dynamic imageFile) async {
    try {
      final fileName = '${_uuid.v4()}.jpg';
      final ref = _storage.ref().child('book_images').child(fileName);
      
      UploadTask uploadTask;
      if (imageFile is Uint8List) {
        // Para web o cuando se pasa Uint8List directamente
        uploadTask = ref.putData(
          imageFile,
          SettableMetadata(contentType: 'image/jpeg'),
        );
      } else if (imageFile is File) {
        // Para mobile o cuando se pasa File
        uploadTask = ref.putFile(
          imageFile,
          SettableMetadata(contentType: 'image/jpeg'),
        );
      } else {
        throw 'Tipo de archivo no válido: ${imageFile.runtimeType}';
      }
      
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      throw 'Error al subir la imagen del libro: ${e.toString()}';
    }
  }

  Future<void> deleteImage(String imageUrl) async {
    try {
      // Validar que la URL no esté vacía
      if (imageUrl.isEmpty) {
        print('URL de imagen vacía, no hay nada que eliminar');
        return;
      }

      // Obtener referencia desde la URL
      final ref = _storage.refFromURL(imageUrl);
      
      // Intentar eliminar el archivo
      await ref.delete();
      print('Imagen eliminada exitosamente: $imageUrl');
    } on FirebaseException catch (e) {
      // Manejar errores específicos de Firebase
      if (e.code == 'object-not-found') {
        print('La imagen ya no existe en Storage: $imageUrl');
        // No lanzar error, ya que el objetivo (que no exista) se cumplió
      } else if (e.code == 'unauthorized') {
        print('No tienes permisos para eliminar esta imagen: $imageUrl');
        // No lanzar error para no bloquear la eliminación del libro
      } else {
        print('Error de Firebase al eliminar imagen: ${e.code} - ${e.message}');
        // No lanzar error para no bloquear la eliminación del libro
      }
    } catch (e) {
      // Cualquier otro error
      print('Error inesperado al eliminar imagen: ${e.toString()}');
      // No lanzar error para no bloquear la eliminación del libro
    }
  }

  Stream<double> uploadWithProgress(File imageFile, String path) {
    final ref = _storage.ref().child(path);
    final uploadTask = ref.putFile(imageFile);
    
    return uploadTask.snapshotEvents.map((snapshot) {
      return snapshot.bytesTransferred / snapshot.totalBytes;
    });
  }
}

