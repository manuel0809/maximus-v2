import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ==========================================
// 1. CAPA DE INICIALIZACIÓN
// ==========================================
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: 'https://zeirkcjvddvkugpsxtit.supabase.co', 
    anonKey: 'sb_publishable_z1A-bV02S3qAC5Upm09DNg_0A8f499m',
  );

  runApp(const MaximusApp());
}

class MaximusApp extends StatelessWidget {
  const MaximusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Maximus Level Group',
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFFD4AF37), // Dorado Premium
        scaffoldBackgroundColor: Colors.black,
      ),
      home: const LuxuryLandingPage(),
    );
  }
}

// ==========================================
// 2. CAPA DE PRESENTACIÓN (UI)
// ==========================================
class LuxuryLandingPage extends StatefulWidget {
  const LuxuryLandingPage({super.key});

  @override
  State<LuxuryLandingPage> createState() => _LuxuryLandingPageState();
}

class _LuxuryLandingPageState extends State<LuxuryLandingPage> {
  // Controladores de texto
  final _nameController = TextEditingController();
  final _pickupController = TextEditingController();
  final _dropoffController = TextEditingController();

  // ==========================================
  // 3. CAPA DE LÓGICA (BUSINESS LOGIC)
  // ==========================================
  Future<void> _processBooking() async {
    // Validación simple
    if (_nameController.text.isEmpty || _pickupController.text.isEmpty) {
      _showNotification("Por favor, complete los campos obligatorios", isError: true);
      return;
    }

    try {
      await Supabase.instance.client.from('reservas').insert({
        'texto del nombre del cliente': _nameController.text,
        'texto de la dirección de recogida': _pickupController.text,
        'texto de la dirección de destino': _dropoffController.text,
        'texto de estado': 'Pendiente de Contacto',
      });

      _showNotification("Solicitud de lujo enviada. Maximus le contactará en breve.");
      _clearFields();
    } catch (e) {
      _showNotification("Error de red. Intente de nuevo.", isError: true);
    }
  }

  void _showNotification(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: isError ? Colors.red : const Color(0xFFD4AF37),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _clearFields() {
    _nameController.clear();
    _pickupController.clear();
    _dropoffController.clear();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _pickupController.dispose();
    _dropoffController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Capa de Fondo (Imagen de alta resolución)
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: NetworkImage('https://images.unsplash.com/photo-1503376780353-7e6692767b70?q=80&w=2000'), // Imagen de auto de lujo
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Capa de Gradiente (Efecto cine)
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.black.withOpacity(0.9), Colors.transparent],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
          ),
          // Capa de Contenido
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 80),
            child: Row(
              children: [
                // Lado Izquierdo: Branding
                Expanded(
                  flex: 2,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("MAXIMUS", 
                        style: TextStyle(color: Color(0xFFD4AF37), fontSize: 90, letterSpacing: 25, fontWeight: FontWeight.w100)),
                      const Text("LEVEL GROUP", 
                        style: TextStyle(color: Colors.white, fontSize: 18, letterSpacing: 10)),
                      const SizedBox(height: 40),
                      const Text("REDEFINING\nEXCLUSIVITY", 
                        style: TextStyle(color: Colors.white, fontSize: 50, fontWeight: FontWeight.bold, height: 1.1)),
                      const SizedBox(height: 30),
                      Container(height: 3, width: 80, color: const Color(0xFFD4AF37)),
                    ],
                  ),
                ),
                // Lado Derecho: Formulario "Glass"
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(40),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.3)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text("REQUEST CHAUFFEUR", style: TextStyle(letterSpacing: 3, fontWeight: FontWeight.bold, color: Colors.white)),
                        const SizedBox(height: 30),
                        _luxuryField(_nameController, "FULL NAME", Icons.person_outline),
                        const SizedBox(height: 20),
                        _luxuryField(_pickupController, "PICKUP LOCATION", Icons.location_on_outlined),
                        const SizedBox(height: 20),
                        _luxuryField(_dropoffController, "DESTINATION", Icons.flag_outlined),
                        const SizedBox(height: 40),
                        ElevatedButton(
                          onPressed: _processBooking,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD4AF37),
                            foregroundColor: Colors.black,
                            minimumSize: const Size(double.infinity, 60),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                          ),
                          child: const Text("BOOK NOW", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _luxuryField(TextEditingController controller, String label, IconData icon) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54, fontSize: 12),
        prefixIcon: Icon(icon, color: const Color(0xFFD4AF37)),
        enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
        focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFD4AF37))),
      ),
    );
  }
}
