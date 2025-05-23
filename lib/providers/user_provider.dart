import 'package:flutter/material.dart';

class UserProvider with ChangeNotifier {
  String? _username;
  String? _profileImagePath;

  String? get username => _username;
  bool get isLoggedIn => _username != null;
  String? get profileImagePath => _profileImagePath;

  void login(String username) {
    _username = username;
    notifyListeners();
  }

  void setUser(String username, {String? profileImagePath}) {
    _username = username;
    _profileImagePath = profileImagePath;
    notifyListeners();
  }

  void updateProfile({String? username, String? profileImagePath}) {
    if (username != null) {
      _username = username;
    }
    
    if (profileImagePath != null) {
      _profileImagePath = profileImagePath;
    }
    
    notifyListeners();
  }

  void logout() {
    _username = null;
    _profileImagePath = null;
    notifyListeners();
  }

  void register(String username) {
    _username = username;
    notifyListeners();
  }
}
