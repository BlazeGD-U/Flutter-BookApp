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
      if (kIsWeb && imageFile is Uint8List) {
        uploadTask = ref.putData(
          imageFile,
          SettableMetadata(contentType: 'image/jpeg'),
        );
      } else if (!kIsWeb && imageFile is File) {
        uploadTask = ref.putFile(
          imageFile,
          SettableMetadata(contentType: 'image/jpeg'),
        );
      } else {
        throw 'Tipo de archivo no válido';
      }
      
      final snapshot = await uploadTask.whenComplete(() => null);
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
      if (kIsWeb && imageFile is Uint8List) {
        uploadTask = ref.putData(
          imageFile,
          SettableMetadata(contentType: 'image/jpeg'),
        );
      } else if (!kIsWeb && imageFile is File) {
        uploadTask = ref.putFile(
          imageFile,
          SettableMetadata(contentType: 'image/jpeg'),
        );
      } else {
        throw 'Tipo de archivo no válido';
      }
      
      final snapshot = await uploadTask.whenComplete(() => null);
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      throw 'Error al subir la imagen del libro: ${e.toString()}';
    }
  }

  Future<void> deleteImage(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      print('Error al eliminar imagen: ${e.toString()}');
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

