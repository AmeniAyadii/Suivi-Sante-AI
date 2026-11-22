import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ReportFormDialog extends StatefulWidget {
  const ReportFormDialog({super.key});

  @override
  State<ReportFormDialog> createState() => _ReportFormDialogState();
}

class _ReportFormDialogState extends State<ReportFormDialog> {
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: const Text('Période personnalisée'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.calendar_today),
            title: Text(_startDate != null
                ? DateFormat('dd/MM/yyyy').format(_startDate!)
                : 'Date de début'),
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: DateTime.now().subtract(const Duration(days: 30)),
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (date != null) {
                setState(() => _startDate = date);
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.calendar_today),
            title: Text(_endDate != null
                ? DateFormat('dd/MM/yyyy').format(_endDate!)
                : 'Date de fin'),
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: _startDate ?? DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (date != null) {
                setState(() => _endDate = date);
              }
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_startDate != null && _endDate != null) {
              Navigator.pop(context, {
                'startDate': _startDate,
                'endDate': _endDate,
              });
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue.shade700,
          ),
          child: const Text('Valider'),
        ),
      ],
    );
  }
}