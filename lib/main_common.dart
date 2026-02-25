import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/config/env_config.dart';
import 'app.dart';

Future<void> mainCommon() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment configurations
  await EnvConfig.instance.load();
  
  // Initialize Supabase
  await Supabase.initialize(
    url: EnvConfig.instance.supabaseUrl,
    anonKey: EnvConfig.instance.supabaseAnonKey,
  );
  
  runApp(const MaximusApp());
}
