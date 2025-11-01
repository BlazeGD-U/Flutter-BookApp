import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/validators.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/image_picker_widget.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();

  File? _selectedImage;
  bool _isChangingPassword = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    if (user != null) {
      _nameController.text = user.name;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleUpdateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();

    // Actualizar perfil
    final success = await authProvider.updateProfile(
      name: _nameController.text.trim(),
      imageFile: _selectedImage,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Perfil actualizado correctamente'),
        ),
      );
      
      // Si se está cambiando la contraseña
      if (_isChangingPassword && 
          _currentPasswordController.text.isNotEmpty &&
          _newPasswordController.text.isNotEmpty) {
        _handleChangePassword();
      } else {
        Navigator.pop(context);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.error ?? 'Error al actualizar el perfil'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleChangePassword() async {
    final authProvider = context.read<AuthProvider>();

    final success = await authProvider.changePassword(
      currentPassword: _currentPasswordController.text,
      newPassword: _newPasswordController.text,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Contraseña cambiada correctamente'),
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.error ?? 'Error al cambiar la contraseña'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Perfil'),
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Selector de imagen
                  Center(
                    child: ImagePickerWidget(
                      imageFile: _selectedImage,
                      imageUrl: user?.photoUrl,
                      onImagePicked: (file) {
                        setState(() {
                          _selectedImage = file;
                        });
                      },
                      width: 120,
                      height: 120,
                      isCircular: true,
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Nombre
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Nombre',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 8),
                  CustomTextField(
                    controller: _nameController,
                    hintText: 'Sofia Rodríguez',
                    validator: Validators.validateName,
                  ),
                  const SizedBox(height: 16),
                  
                  // Email (solo lectura)
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Email',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 8),
                  CustomTextField(
                    controller: TextEditingController(text: user?.email ?? ''),
                    hintText: 'sofia.rodriguez@email.com',
                    readOnly: true,
                  ),
                  const SizedBox(height: 32),
                  
                  // Cambiar contraseña
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Cambiar contraseña',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Contraseña actual
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Contraseña actual',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 8),
                  CustomTextField(
                    controller: _currentPasswordController,
                    hintText: '••••••••',
                    obscureText: true,
                    onTap: () {
                      setState(() {
                        _isChangingPassword = true;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Nueva contraseña
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Nueva contraseña',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 8),
                  CustomTextField(
                    controller: _newPasswordController,
                    hintText: '••••••••',
                    obscureText: true,
                    validator: _isChangingPassword
                        ? Validators.validatePassword
                        : null,
                    onTap: () {
                      setState(() {
                        _isChangingPassword = true;
                      });
                    },
                  ),
                  const SizedBox(height: 32),
                  
                  // Botón de guardar
                  CustomButton(
                    text: 'Guardar cambios',
                    onPressed: _handleUpdateProfile,
                    isLoading: authProvider.isLoading,
                  ),
                  const SizedBox(height: 16),
                  
                  // Botón de cerrar sesión (en rojo)
                  CustomButton(
                    text: 'Cerrar sesión',
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    isOutlined: true,
                    backgroundColor: Colors.white,
                    textColor: Colors.red,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

