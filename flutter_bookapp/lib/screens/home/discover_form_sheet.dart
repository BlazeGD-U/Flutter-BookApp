import 'package:flutter/material.dart';
import '../../config/app_config.dart';
import '../../services/groq_service.dart';
import '../../utils/constants.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import 'discover_result_screen.dart';

class DiscoverFormSheet extends StatefulWidget {
  const DiscoverFormSheet({super.key});

  @override
  State<DiscoverFormSheet> createState() => _DiscoverFormSheetState();
}

class _DiscoverFormSheetState extends State<DiscoverFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _authorController = TextEditingController();
  final _pagesController = TextEditingController();
  final _hoursController = TextEditingController();
  final _groqService = GroqService();

  String? _selectedGenre;
  bool _isLoading = false;

  @override
  void dispose() {
    _authorController.dispose();
    _pagesController.dispose();
    _hoursController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (!AppConfig.isGroqConfigured) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Configura GROQ_API_KEY en el archivo .env para usar Descubre',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final recommendation = await _groqService.getDiscoverRecommendation(
        genre: _selectedGenre!,
        favoriteAuthor: _authorController.text.trim(),
        averagePages: _pagesController.text.trim(),
        freeHoursPerDay: _hoursController.text.trim(),
      );

      if (!mounted) return;

      if (!recommendation.isValid) {
        throw 'La recomendación recibida no es válida';
      }

      Navigator.pop(context);
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => DiscoverResultScreen(recommendation: recommendation),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Descubre tu próximo libro',
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                  ),
                  IconButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Responde estas preguntas y la IA te recomendará un libro a tu medida.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: _selectedGenre,
                decoration: const InputDecoration(
                  labelText: '¿Qué género te gusta más?',
                ),
                items: AppConstants.categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: _isLoading
                    ? null
                    : (value) => setState(() => _selectedGenre = value),
                validator: (value) =>
                    value == null ? 'Selecciona un género' : null,
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: _authorController,
                hintText: '¿Qué autor te gusta en ese género? (Ej: Stephen King)',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ingresa un autor';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: _pagesController,
                hintText: '¿Cuántas páginas lees en promedio? (Ej: 30)',
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ingresa un número aproximado';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: _hoursController,
                hintText: '¿Cuántas horas libres tienes al día? (Ej: 1.5)',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ingresa tus horas disponibles';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              CustomButton(
                text: _isLoading ? 'Buscando recomendación...' : 'Obtener recomendación',
                onPressed: () {
                  if (!_isLoading) _submit();
                },
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
