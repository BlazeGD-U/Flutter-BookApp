import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../utils/constants.dart';

class ImagePickerWidget extends StatelessWidget {
  final dynamic imageFile; // File en mobile, Uint8List en web
  final String? imageUrl;
  final Function(dynamic) onImagePicked; // Acepta File o Uint8List
  final String placeholder;
  final double width;
  final double height;
  final bool isCircular;

  const ImagePickerWidget({
    super.key,
    this.imageFile,
    this.imageUrl,
    required this.onImagePicked,
    this.placeholder = 'Tap to upload',
    this.width = 150,
    this.height = 150,
    this.isCircular = false,
  });

  Future<void> _pickImage(BuildContext context) async {
    final ImagePicker picker = ImagePicker();
    
    // Mostrar opciones (solo para mobile)
    ImageSource? source;
    if (kIsWeb) {
      source = ImageSource.gallery;
    } else {
      source = await showModalBottomSheet<ImageSource>(
        context: context,
        builder: (context) => SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Galería'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Cámara'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
            ],
          ),
        ),
      );
    }

    if (source != null) {
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        // Verificar tamaño del archivo
        final fileBytes = await image.readAsBytes();
        if (fileBytes.lengthInBytes > AppConstants.maxImageSizeBytes) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('La imagen es muy grande. Máximo 5MB'),
              ),
            );
          }
          return;
        }

        // En web usar Uint8List, en mobile usar File
        if (kIsWeb) {
          onImagePicked(fileBytes);
        } else {
          final file = File(image.path);
          onImagePicked(file);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _pickImage(context),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppConstants.secondaryColor,
          shape: isCircular ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: isCircular ? null : BorderRadius.circular(12),
          border: Border.all(
            color: AppConstants.primaryColor.withOpacity(0.3),
            width: 2,
            style: BorderStyle.solid,
          ),
        ),
        child: ClipRRect(
          borderRadius: isCircular
              ? BorderRadius.circular(width / 2)
              : BorderRadius.circular(12),
          child: _buildImage(context),
        ),
      ),
    );
  }

  Widget _buildImage(BuildContext context) {
    // Si hay un archivo seleccionado
    if (imageFile != null) {
      if (kIsWeb && imageFile is Uint8List) {
        // En web, usar Uint8List
        return Image.memory(
          imageFile as Uint8List,
          fit: BoxFit.cover,
        );
      } else if (!kIsWeb && imageFile is File) {
        // En mobile, usar File
        return Image.file(
          imageFile as File,
          fit: BoxFit.cover,
        );
      }
    }

    // Si hay una URL de imagen
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return Image.network(
        imageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
      );
    }

    // Placeholder
    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          isCircular ? Icons.person : Icons.cloud_upload,
          size: 48,
          color: AppConstants.textSecondaryColor,
        ),
        const SizedBox(height: 8),
        Text(
          placeholder,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: AppConstants.textSecondaryColor,
          ),
        ),
      ],
    );
  }
}

