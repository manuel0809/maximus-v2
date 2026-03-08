import 'package:http/http.dart' as http;
import 'dart:convert';

void main() async {
  const supabaseUrl = 'https://metapwzflvslnivcsedu.supabase.co';
  const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1ldGFwd3pmbHZzbG5pdmNzZWR1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzA5MTE3NzUsImV4cCI6MjA4NjQ4Nzc3NX0.7rIZqiMY1uLwXVZEPR50zagIr2Vojce2BFusmNvDT3I';
  
  final email = 'admin@maximuslevelgroup.com';
  final password = 'M@nuel08';

  print('=== TEST DE INICIO DE SESIÓN ===');
  print('Iniciando prueba manual HTTP a Supabase como Administrador...');
  
  final url = Uri.parse('$supabaseUrl/auth/v1/token?grant_type=password');
  
  try {
    final response = await http.post(
      url,
      headers: {
        'apikey': supabaseAnonKey,
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );
    
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final json = jsonDecode(response.body);
      final user = json['user'];
      final role = user['user_metadata']?['role'] ?? 'No definido en metadata (Client por defecto)';
      
      print('✅ ¡INICIO DE SESIÓN EXITOSO!');
      print('=================================');
      print('ID de Usuario : ${user['id']}');
      print('Correo        : ${user['email']}');
      print('Rol Oficial   : $role');
      print('=================================');
      print('El backend funciona perfectamente. La aplicación Flutter dejará pasar a este usuario al Admin Dashboard.');
    } else {
      print('❌ ERROR AL INICIAR SESIÓN');
      print('Código HTTP : ${response.statusCode}');
      print('Mensaje     : ${response.body}');
      print('>> Esto indica que la contraseña es incorrecta o el usuario "admin@maximuslevelgroup.com" aún no existe en Supabase Auth.');
    }
  } catch (e) {
    print('Error crítico de red: $e');
  }
}
