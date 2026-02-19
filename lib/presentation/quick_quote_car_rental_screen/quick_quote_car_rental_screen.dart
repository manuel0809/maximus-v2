import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_icon_widget.dart';

class QuickQuoteCarRentalScreen extends StatefulWidget {
  const QuickQuoteCarRentalScreen({super.key});

  @override
  State<QuickQuoteCarRentalScreen> createState() =>
      _QuickQuoteCarRentalScreenState();
}

class _QuickQuoteCarRentalScreenState extends State<QuickQuoteCarRentalScreen> {
  // Form controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _pickupLocationController =
      TextEditingController();
  final TextEditingController _dropoffLocationController =
      TextEditingController();

  // Date selections
  DateTime? _pickupDate;
  DateTime? _dropoffDate;

  // Vehicle type selection
  String _selectedVehicleType = 'económico';

  // Price map
  final Map<String, double> _prices = {
    'económico': 25.0,
    'suv': 45.0,
    'lujo': 85.0,
  };

  // Loading state
  bool _isSending = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _pickupLocationController.dispose();
    _dropoffLocationController.dispose();
    super.dispose();
  }

  double _calculateTotal() {
    if (_pickupDate == null || _dropoffDate == null) return 0.0;
    final days = _dropoffDate!.difference(_pickupDate!).inDays;
    final totalDays = days > 0 ? days : 1;
    return _prices[_selectedVehicleType]! * totalDays;
  }

  int _calculateDays() {
    if (_pickupDate == null || _dropoffDate == null) return 0;
    final days = _dropoffDate!.difference(_pickupDate!).inDays;
    return days > 0 ? days : 1;
  }

  Future<void> _selectDate(BuildContext context, bool isPickup) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isPickup
          ? (_pickupDate ?? DateTime.now())
          : (_dropoffDate ?? DateTime.now().add(const Duration(days: 1))),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).colorScheme.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isPickup) {
          _pickupDate = picked;
          // Auto-adjust dropoff if it's before pickup
          if (_dropoffDate != null && _dropoffDate!.isBefore(picked)) {
            _dropoffDate = picked.add(const Duration(days: 1));
          }
        } else {
          _dropoffDate = picked;
        }
      });
    }
  }

  Future<void> _sendWhatsAppQuote() async {
    // Validate required fields
    if (_nameController.text.trim().isEmpty) {
      _showSnackBar('Por favor ingresa tu nombre');
      return;
    }

    if (_phoneController.text.trim().isEmpty) {
      _showSnackBar('Por favor ingresa tu número de WhatsApp');
      return;
    }

    if (_pickupLocationController.text.trim().isEmpty) {
      _showSnackBar('Por favor ingresa el lugar de recogida');
      return;
    }

    if (_pickupDate == null || _dropoffDate == null) {
      _showSnackBar('Por favor selecciona las fechas de recogida y devolución');
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      final total = _calculateTotal();
      final days = _calculateDays();
      final pickupDateStr = DateFormat('dd/MM/yyyy').format(_pickupDate!);
      final dropoffDateStr = DateFormat('dd/MM/yyyy').format(_dropoffDate!);
      final now = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());

      final message = '''
🚗 *NUEVA COTIZACIÓN - SIN REGISTRO*
────────────────
👤 *Cliente:* ${_nameController.text.trim()}
📱 *WhatsApp:* ${_phoneController.text.trim()}

📍 *Recogida:* ${_pickupLocationController.text.trim()}
🏁 *Devolución:* ${_dropoffLocationController.text.trim().isEmpty ? 'Mismo lugar de recogida' : _dropoffLocationController.text.trim()}
📅 *Fechas:* $pickupDateStr al $dropoffDateStr ($days días)
🚘 *Vehículo:* ${_selectedVehicleType.toUpperCase()}

💰 *Total estimado:* \$${total.toStringAsFixed(2)} USD
────────────────

⏱️ *Enviado:* $now
''';

      // WhatsApp admin number - configured from environment or default
      const String adminWhatsAppNumber =
          String.fromEnvironment('WHATSAPP_ADMIN_NUMBER',
              defaultValue: '521234567890');

      final Uri whatsappUrl = Uri.parse(
          'https://wa.me/$adminWhatsAppNumber?text=${Uri.encodeComponent(message)}');

      if (await canLaunchUrl(whatsappUrl)) {
        await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
        if (mounted) {
          _showSnackBar('Abriendo WhatsApp...', isSuccess: true);
        }
      } else {
        if (mounted) {
          _showSnackBar('No se pudo abrir WhatsApp. Verifica que esté instalado.');
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error al enviar cotización. Intenta nuevamente.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  void _showSnackBar(String message, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isSuccess ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = _calculateTotal();
    final days = _calculateDays();

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: const CustomAppBar(
        title: 'Cotización Rápida',
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with badge
            Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.primaryContainer,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(2.w),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: const CustomIconWidget(
                          iconName: 'chat',
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      SizedBox(width: 3.w),
                      Expanded(
                        child: Text(
                          'Cotización rápida',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 2.h),
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E7D32),
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: Colors.white,
                          size: 16,
                        ),
                        SizedBox(width: 1.w),
                        Text(
                          'Sin registro • Respuesta inmediata',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 3.h),

            // Contact Information Section
            Text(
              '👤 Información de Contacto',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 1.5.h),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Tu nombre',
                      hintText: 'Ej: Juan Pérez',
                      prefixIcon: Icon(
                        Icons.person,
                        color: theme.colorScheme.primary,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: BorderSide(
                          color: theme.colorScheme.primary,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'WhatsApp',
                      hintText: 'Ej: 521234567890',
                      prefixIcon: Icon(
                        Icons.phone,
                        color: theme.colorScheme.primary,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: BorderSide(
                          color: theme.colorScheme.primary,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 3.h),

            // Location Section
            Text(
              '📍 Ubicaciones',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 1.5.h),
            TextField(
              controller: _pickupLocationController,
              decoration: InputDecoration(
                labelText: 'Lugar de recogida',
                hintText: 'Ej: Aeropuerto',
                prefixIcon: Icon(
                  Icons.location_on,
                  color: theme.colorScheme.primary,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide(
                    color: theme.colorScheme.primary,
                    width: 2,
                  ),
                ),
              ),
            ),
            SizedBox(height: 1.5.h),
            TextField(
              controller: _dropoffLocationController,
              decoration: InputDecoration(
                labelText: 'Lugar de devolución (opcional)',
                hintText: 'Ej: Hotel Centro',
                prefixIcon: Icon(
                  Icons.flag,
                  color: theme.colorScheme.primary,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide(
                    color: theme.colorScheme.primary,
                    width: 2,
                  ),
                ),
              ),
            ),
            SizedBox(height: 3.h),

            // Dates Section
            Text(
              '📅 Fechas',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 1.5.h),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDate(context, true),
                    child: Container(
                      padding: EdgeInsets.all(3.w),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: theme.colorScheme.outline.withValues(alpha: 0.5),
                        ),
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            color: theme.colorScheme.primary,
                            size: 20,
                          ),
                          SizedBox(width: 2.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Fecha de recogida',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.6),
                                  ),
                                ),
                                SizedBox(height: 0.5.h),
                                Text(
                                  _pickupDate != null
                                      ? DateFormat('dd/MM/yyyy')
                                          .format(_pickupDate!)
                                      : 'Seleccionar',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDate(context, false),
                    child: Container(
                      padding: EdgeInsets.all(3.w),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: theme.colorScheme.outline.withValues(alpha: 0.5),
                        ),
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            color: theme.colorScheme.primary,
                            size: 20,
                          ),
                          SizedBox(width: 2.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Fecha de devolución',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.6),
                                  ),
                                ),
                                SizedBox(height: 0.5.h),
                                Text(
                                  _dropoffDate != null
                                      ? DateFormat('dd/MM/yyyy')
                                          .format(_dropoffDate!)
                                      : 'Seleccionar',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (days > 0) ...[
              SizedBox(height: 1.h),
              Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color:
                      theme.colorScheme.primaryContainer.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.schedule,
                      color: theme.colorScheme.primary,
                      size: 16,
                    ),
                    SizedBox(width: 2.w),
                    Text(
                      'Duración: $days ${days == 1 ? "día" : "días"}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            SizedBox(height: 3.h),

            // Vehicle Type Section
            Text(
              '🚗 Tipo de vehículo',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 1.5.h),
            Row(
              children: [
                Expanded(
                  child: _buildVehicleTypeCard(
                    context,
                    'económico',
                    '💰',
                    'Económico',
                    _prices['económico']!,
                  ),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: _buildVehicleTypeCard(
                    context,
                    'suv',
                    '🚙',
                    'SUV',
                    _prices['suv']!,
                  ),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: _buildVehicleTypeCard(
                    context,
                    'lujo',
                    '✨',
                    'Lujo',
                    _prices['lujo']!,
                  ),
                ),
              ],
            ),
            SizedBox(height: 3.h),

            // Total and WhatsApp Button
            Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16.0),
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.2),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total estimado:',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '\$${total.toStringAsFixed(2)}',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              color: const Color(0xFF2E7D32),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'USD',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 2.h),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSending ? null : _sendWhatsAppQuote,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 2.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        elevation: 2,
                      ),
                      child: _isSending
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.chat, size: 24),
                                SizedBox(width: 2.w),
                                Text(
                                  'Recibir cotización por WhatsApp',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  SizedBox(height: 1.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.flash_on,
                        size: 14,
                        color: Color(0xFFF57C00),
                      ),
                      SizedBox(width: 1.w),
                      Text(
                        'Sin registro • Respuesta en minutos',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color:
                              theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleTypeCard(
    BuildContext context,
    String type,
    String emoji,
    String label,
    double price,
  ) {
    final theme = Theme.of(context);
    final isSelected = _selectedVehicleType == type;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedVehicleType = type;
        });
      },
      child: Container(
        padding: EdgeInsets.all(3.w),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primaryContainer.withValues(alpha: 0.1)
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(
              emoji,
              style: const TextStyle(fontSize: 32),
            ),
            SizedBox(height: 1.h),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 0.5.h),
            Text(
              '\$${price.toStringAsFixed(0)}/día',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}