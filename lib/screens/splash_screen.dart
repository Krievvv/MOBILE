import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../providers/user_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    try {
      // Wait a bit for splash effect
      await Future.delayed(const Duration(seconds: 2));

      final session = supabase.Supabase.instance.client.auth.currentSession;
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      if (session != null && mounted) {
        // User is logged in, set user in provider
        final email = session.user.email ?? 'Unknown';
        userProvider.setUser(email);

        // Navigate to main screen
        Navigator.of(context).pushReplacementNamed('/main');
      } else if (mounted) {
        // No session, go to login
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } catch (e) {
      print('Error checking auth status: $e');
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.orange.shade300,
              Colors.orange.shade100,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App Logo/Icon
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      spreadRadius: 2,
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.library_books,
                  size: 80,
                  color: Colors.orange.shade700,
                ),
              ),
              const SizedBox(height: 40),

              // App Name
              Text(
                'Pustakasaku',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade800,
                ),
              ),
              const SizedBox(height: 12),

              // Tagline
              Text(
                'Kelola koleksi buku Anda',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.orange.shade700,
                ),
              ),
              const SizedBox(height: 60),

              // Loading Indicator
              CircularProgressIndicator(
                valueColor:
                    AlwaysStoppedAnimation<Color>(Colors.orange.shade700),
                strokeWidth: 3,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
