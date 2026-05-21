import 'package:flutter/material.dart';
import '../utils/constants.dart';

class ReadingTimerDialog extends StatefulWidget {
  const ReadingTimerDialog({super.key});

  @override
  State<ReadingTimerDialog> createState() => _ReadingTimerDialogState();
}

class _ReadingTimerDialogState extends State<ReadingTimerDialog> {
  final _amountController = TextEditingController(text: '15');
  bool _useHours = false;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Duration? _buildDuration() {
    final value = int.tryParse(_amountController.text.trim());
    if (value == null || value <= 0) return null;

    if (_useHours) {
      if (value > 12) return null;
      return Duration(hours: value);
    }

    if (value > 600) return null;
    return Duration(minutes: value);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tiempo de lectura'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Elige cuánto tiempo quieres concentrarte leyendo este libro.',
          ),
          const SizedBox(height: 16),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: false, label: Text('Minutos')),
              ButtonSegment(value: true, label: Text('Horas')),
            ],
            selected: {_useHours},
            onSelectionChanged: (selection) {
              setState(() => _useHours = selection.first);
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: _useHours ? 'Horas' : 'Minutos',
              hintText: _useHours ? 'Ej: 1' : 'Ej: 15',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            final duration = _buildDuration();
            if (duration == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Ingresa un tiempo válido'),
                ),
              );
              return;
            }
            Navigator.pop(context, duration);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppConstants.primaryColor,
          ),
          child: const Text('Aceptar'),
        ),
      ],
    );
  }
}
