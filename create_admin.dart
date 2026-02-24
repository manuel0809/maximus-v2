
import 'package:supabase/supabase.dart';
import 'package:flutter/foundation.dart';

void main() async {
  const supabaseUrl = 'https://metapwzflvslnivcsedu.supabase.co';
  const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1ldGFwd3pmbHZzbG5pdmNzZWR1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzA5MTE3NzUsImV4cCI6MjA4NjQ4Nzc3NX0.7rIZqiMY1uLwXVZEPR50zagIr2Vojce2BFusmNvDT3I';

  final supabase = SupabaseClient(supabaseUrl, supabaseKey);

  final email = 'admin@maximuslevelgroup.com';
  final password = 'M@nuel08';

  try {
    debugPrint('Creating admin user...');
    
    final response = await supabase.auth.signUp(
      email: email,
      password: password,
      data: {
        'role': 'admin',
        'full_name': 'Administrador Principal',
      },
    );

    if (response.user != null) {
      debugPrint('✅ Admin user created successfully!');
      debugPrint('Email: $email');
      debugPrint('Password: $password');
      debugPrint('ID: ${response.user!.id}');
    } else {
      debugPrint('⚠️ User creation response was null (might be existing user or email confirmation required).');
    }
  } catch (e, stackTrace) {
    debugPrint('❌ Error creating user: $e');
    debugPrint('Stack trace: $stackTrace');
  }
}
