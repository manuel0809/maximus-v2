
import 'package:supabase/supabase.dart';

void main() async {
  const supabaseUrl = 'https://metapwzflvslnivcsedu.supabase.co';
  const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1ldGFwd3pmbHZzbG5pdmNzZWR1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzA5MTE3NzUsImV4cCI6MjA4NjQ4Nzc3NX0.7rIZqiMY1uLwXVZEPR50zagIr2Vojce2BFusmNvDT3I';

  final supabase = SupabaseClient(supabaseUrl, supabaseKey);

  final email = 'nin@maximuslevelgroup.com';
  final password = 'M@nuel08'; // Using the same password as the admin account

  try {
    print('Attempts to create user: $email...');
    
    final response = await supabase.auth.signUp(
      email: email,
      password: password,
      data: {
        'role': 'admin', // Setting as admin just in case
        'full_name': 'Nin Admin',
      },
    );

    if (response.user != null) {
      if (response.user!.identities != null && response.user!.identities!.isNotEmpty) {
        print('✅ User $email created successfully!');
        print('Password: $password');
        print('Please try logging in with these credentials.');
      } else {
        print('⚠️ User $email already exists (or requires email confirmation).');
        print('If it exists, please use the correct password.');
        print('Alternatively, try logging in with: admin@maximuslevelgroup.com / M@nuel08');
      }
    } else {
      print('⚠️ Unexpected response (User is null).');
    }
  } catch (e) {
    print('❌ Error: $e');
  }
}
