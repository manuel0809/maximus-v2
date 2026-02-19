import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../services/finance_service.dart';
import '../../../services/car_rental_service.dart';
import '../../../widgets/custom_app_bar.dart';
import '../widgets/kpi_card_widget.dart';

class FinancialReportsScreen extends StatefulWidget {
  const FinancialReportsScreen({super.key});

  @override
  State<FinancialReportsScreen> createState() => _FinancialReportsScreenState();
}

class _FinancialReportsScreenState extends State<FinancialReportsScreen> {
  final FinanceService _financeService = FinanceService.instance;
  Map<String, dynamic>? summary;
  List<Map<String, dynamic>> profitability = [];
  String selectedPeriod = 'Este Mes';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFinanceData();
  }

  Future<void> _loadFinanceData() async {
    final sData = await _financeService.getFinancialSummary(selectedPeriod);
    final pData = await _financeService.getProfitabilityReport();
    if (mounted) {
      setState(() {
        summary = sData;
        profitability = pData;
        isLoading = false;
      });
    }
  }

  void _showAddExpenseDialog() async {
    final vehicles = await _carService.getVehicles();
    if (!mounted) return;

    String selectedVehicleId = vehicles.isNotEmpty ? vehicles[0]['id'] : '';
    String selectedType = 'maintenance';
    final amountController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Registrar Gasto'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: selectedVehicleId,
                  decoration: const InputDecoration(labelText: 'Vehículo'),
                  items: vehicles.map((v) => DropdownMenuItem(
                    value: v['id'].toString(),
                    child: Text('${v['brand']} ${v['model']}'),
                  )).toList(),
                  onChanged: (val) => setDialogState(() => selectedVehicleId = val!),
                ),
                SizedBox(height: 2.h),
                DropdownButtonFormField<String>(
                  initialValue: selectedType,
                  decoration: const InputDecoration(labelText: 'Tipo de Gasto'),
                  items: const [
                    DropdownMenuItem(value: 'maintenance', child: Text('Mantenimiento')),
                    DropdownMenuItem(value: 'fuel', child: Text('Gasolina')),
                    DropdownMenuItem(value: 'insurance', child: Text('Seguro')),
                    DropdownMenuItem(value: 'fine', child: Text('Multa')),
                    DropdownMenuItem(value: 'cleaning', child: Text('Limpieza')),
                    DropdownMenuItem(value: 'other', child: Text('Otro')),
                  ],
                  onChanged: (val) => setDialogState(() => selectedType = val!),
                ),
                SizedBox(height: 2.h),
                TextField(
                  controller: amountController,
                  decoration: const InputDecoration(labelText: 'Monto (USD)', prefixText: '\$'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(labelText: 'Descripción / Nota'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () async {
                if (amountController.text.isEmpty) return;
                try {
                  await _financeService.addExpense(
                    vehicleId: selectedVehicleId,
                    type: selectedType,
                    amount: double.parse(amountController.text),
                    description: descController.text,
                    date: DateTime.now(),
                  );
                  if (context.mounted) {
                    Navigator.pop(context);
                    _loadFinanceData();
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gasto registrado exitosamente')));
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  // Need CarRentalService for vehicle list
  final CarRentalService _carService = CarRentalService.instance;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Reportes Financieros',
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: _showAddExpenseDialog,
            tooltip: 'Registrar Gasto',
          ),
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Generando reporte PDF...')));
            },
          ),
          SizedBox(width: 2.w),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(4.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPeriodSelector(),
                  SizedBox(height: 3.h),
                  _buildMainKPIs(),
                  SizedBox(height: 4.h),
                  const Text('Desglose de Gastos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  SizedBox(height: 2.h),
                  _buildExpensesBreakdown(theme),
                  SizedBox(height: 4.h),
                  const Text('Rentabilidad por Vehículo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  SizedBox(height: 2.h),
                  _buildVehicleROIList(theme),
                ],
              ),
            ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
      child: DropdownButton<String>(
        value: selectedPeriod,
        isExpanded: true,
        underline: Container(),
        items: ['Hoy', 'Esta Semana', 'Este Mes', 'Este Año'].map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
        onChanged: (val) {
          setState(() => selectedPeriod = val!);
          _loadFinanceData();
        },
      ),
    );
  }

  Widget _buildMainKPIs() {
    return Column(
      children: [
        KPICardWidget(
          title: 'Ingresos Totales',
          value: '\$${summary?['total_income']?.toStringAsFixed(2) ?? '0.00'}',
          icon: Icons.add_chart,
          color: Colors.green,
        ),
        SizedBox(height: 2.h),
        Row(
          children: [
            Expanded(
              child: KPICardWidget(
                title: 'Gastos',
                value: '\$${summary?['total_expenses']?.toStringAsFixed(2) ?? '0.00'}',
                icon: Icons.trending_down,
                color: Colors.red,
              ),
            ),
            SizedBox(width: 4.w),
            Expanded(
              child: KPICardWidget(
                title: 'Utilidad Neta',
                value: '\$${summary?['net_profit']?.toStringAsFixed(2) ?? '0.00'}',
                icon: Icons.account_balance_wallet,
                color: const Color(0xFF8B1538),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildExpensesBreakdown(ThemeData theme) {
    final breakdown = summary?['expenses_breakdown'] as Map<String, dynamic>? ?? {};
    return Card(
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          children: breakdown.entries.map((e) {
            return Padding(
              padding: EdgeInsets.only(bottom: 1.5.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(e.key),
                  Text('\$${(e.value as double).toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildVehicleROIList(ThemeData theme) {
    if (profitability.isEmpty) {
      return const Center(child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Text('No hay datos suficientes para el ROI.'),
      ));
    }
    return Card(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: profitability.length,
        separatorBuilder: (_, __) => const Divider(),
        itemBuilder: (context, index) {
          final v = profitability[index];
          final profit = (v['net_profit'] ?? 0).toDouble();
          final revenue = (v['total_revenue'] ?? 1).toDouble(); // avoid div by zero
          final roi = (profit / revenue * 100).toStringAsFixed(1);
          
          return ListTile(
            title: Text('${v['brand']} ${v['model']}'),
            subtitle: Text('Ganancia neta: \$${profit.toStringAsFixed(2)}'),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('$roi%', style: TextStyle(
                  color: profit >= 0 ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                )),
                const Text('ROI', style: TextStyle(fontSize: 10)),
              ],
            ),
          );
        },
      ),
    );
  }
}
