import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/book_model.dart';
import '../../providers/book_provider.dart';
import '../../utils/constants.dart';
import '../../utils/validators.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/image_picker_widget.dart';

class AddEditBookScreen extends StatefulWidget {
  final String userId;
  final BookModel? book;

  const AddEditBookScreen({
    super.key,
    required this.userId,
    this.book,
  });

  @override
  State<AddEditBookScreen> createState() => _AddEditBookScreenState();
}

class _AddEditBookScreenState extends State<AddEditBookScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _selectedCategory = AppConstants.categories[0];
  String _selectedStatus = AppConstants.bookStatus[0];
  File? _selectedImage;

  bool get isEditing => widget.book != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _titleController.text = widget.book!.title;
      _authorController.text = widget.book!.author;
      _descriptionController.text = widget.book!.description;
      _selectedCategory = widget.book!.category;
      _selectedStatus = widget.book!.status;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final bookProvider = context.read<BookProvider>();

    final success = isEditing
        ? await bookProvider.updateBook(
            book: widget.book!,
            title: _titleController.text.trim(),
            author: _authorController.text.trim(),
            category: _selectedCategory,
            status: _selectedStatus,
            description: _descriptionController.text.trim(),
            imageFile: _selectedImage,
          )
        : await bookProvider.addBook(
            userId: widget.userId,
            title: _titleController.text.trim(),
            author: _authorController.text.trim(),
            category: _selectedCategory,
            status: _selectedStatus,
            description: _descriptionController.text.trim(),
            imageFile: _selectedImage,
          );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEditing
                ? 'Libro actualizado correctamente'
                : 'Libro agregado correctamente',
          ),
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(bookProvider.error ?? 'Error al guardar el libro'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Perfil' : 'Add New Book'),
      ),
      body: Consumer<BookProvider>(
        builder: (context, bookProvider, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Selector de imagen
                  Center(
                    child: ImagePickerWidget(
                      imageFile: _selectedImage,
                      imageUrl: isEditing ? widget.book!.imageUrl : null,
                      onImagePicked: (file) {
                        setState(() {
                          _selectedImage = file;
                        });
                      },
                      placeholder: 'Tap to upload\nor drag and drop\nPNG, JPG or GIF (MAX. 800x400px)',
                      width: double.infinity,
                      height: 200,
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Título
                  const Text(
                    'Title',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  CustomTextField(
                    controller: _titleController,
                    hintText: 'Enter book title',
                    validator: Validators.validateBookTitle,
                  ),
                  const SizedBox(height: 16),
                  
                  // Autor
                  const Text(
                    'Author',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  CustomTextField(
                    controller: _authorController,
                    hintText: 'Enter author\'s name',
                    validator: Validators.validateAuthor,
                  ),
                  const SizedBox(height: 16),
                  
                  // Categoría
                  const Text(
                    'Category',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: const InputDecoration(
                      hintText: 'Select category',
                    ),
                    items: AppConstants.categories.map((category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedCategory = value;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Estado
                  const Text(
                    'Status',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedStatus,
                    decoration: const InputDecoration(
                      hintText: 'Select status',
                    ),
                    items: AppConstants.bookStatus.map((status) {
                      return DropdownMenuItem(
                        value: status,
                        child: Text(status),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedStatus = value;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Descripción
                  const Text(
                    'Description',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  CustomTextField(
                    controller: _descriptionController,
                    hintText: 'Enter book description',
                    maxLines: 5,
                    validator: Validators.validateDescription,
                  ),
                  const SizedBox(height: 32),
                  
                  // Botón de guardar
                  CustomButton(
                    text: isEditing ? 'Guardar cambios' : 'Add Book',
                    onPressed: _handleSubmit,
                    isLoading: bookProvider.isLoading,
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

