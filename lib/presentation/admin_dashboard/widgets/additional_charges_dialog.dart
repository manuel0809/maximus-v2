import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class AdditionalChargesDialog extends StatefulWidget {
  final Map<String, dynamic> rental;

  const AdditionalChargesDialog({super.key, required this.rental});

  @override
  State<AdditionalChargesDialog> createState() => _AdditionalChargesDialogState();
}

class _AdditionalChargesDialogState extends State<AdditionalChargesDialog> {
  final _lateFeeController = TextEditingController();
  final _fuelFeeController = TextEditingController();
  final _damageFeeController = TextEditingController();
  final _notesController = TextEditingController();
  
  double total = 0;

  void _calculateTotal() {
    setState(() {
      total = (double.tryParse(_lateFeeController.text) ?? 0) +
              (double.tryParse(_fuelFeeController.text) ?? 0) +
              (double.tryParse(_damageFeeController.text) ?? 0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Registrar Cargos Adicionales'),
      content: SingleChildScrollView(
        child: Column(
          children: [
            _buildChargeField('Retraso de Devolución', _lateFeeController),
            _buildChargeField('Combustible Faltante', _fuelFeeController),
            _buildChargeField('Daños Identificados', _damageFeeController),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(labelText: 'Notas / Observaciones'),
              maxLines: 2,
            ),
            SizedBox(height: 2.h),
            Text(
              'Total Adicional: \$${total.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF8B1538)),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        ElevatedButton(
          onPressed: () {
            // Logic to save charges and generate invoice
            Navigator.pop(context, {'total': total, 'notes': _notesController.text});
          },
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B1538), foregroundColor: Colors.white),
          child: const Text('Aplicar Cargos'),
        ),
      ],
    );
  }

  Widget _buildChargeField(String label, TextEditingController controller) {
    return Padding(
      padding: EdgeInsets.only(bottom: 1.h),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(labelText: label, prefixText: '\$'),
        onChanged: (_) => _calculateTotal(),
      ),
    );
  }
}
