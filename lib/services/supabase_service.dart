import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: 'YOUR_SUPABASE_URL', // e.g., https://your-project.supabase.co
      anonKey: 'YOUR_ANON_PUBLIC_KEY',
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}