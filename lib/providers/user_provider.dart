import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

class UserProvider with ChangeNotifier {
  String? _username;
  String? _email;
  bool _isLoggedIn = false;

  String? get username => _username;
  String? get email => _email;
  bool get isLoggedIn => _isLoggedIn;

  UserProvider() {
    _checkAuthStatus();
  }

  void _checkAuthStatus() {
    final session = supabase.Supabase.instance.client.auth.currentSession;
    if (session != null) {
      _isLoggedIn = true;
      _email = session.user.email;
      _username = session.user.email; // You can modify this to get username from profile
      notifyListeners();
    }
  }

  void setUser(String email, {String? username}) {
    _email = email;
    _username = username ?? email;
    _isLoggedIn = true;
    notifyListeners();
  }

  void register(String username) {
    _username = username;
    // Don't set isLoggedIn to true here, wait for actual login
    notifyListeners();
  }

  Future<void> logout() async {
    try {
      await supabase.Supabase.instance.client.auth.signOut();
      _username = null;
      _email = null;
      _isLoggedIn = false;
      notifyListeners();
    } catch (e) {
      print('Error during logout: $e');
      // Even if there's an error, clear local state
      _username = null;
      _email = null;
      _isLoggedIn = false;
      notifyListeners();
    }
  }

  void updateProfile({String? username, String? profileImagePath}) {
    if (username != null) {
      _username = username;
    }
    // You can add profileImagePath handling here if needed
    notifyListeners();
  }
}
