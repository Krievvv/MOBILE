import '../models/user.dart';

class AuthService {
  User? _currentUser;

  User? get currentUser => _currentUser;

  bool login(String email, String password) {
    if (email == "test@example.com" && password == "password") {
      _currentUser = User(id: "1", username: "Test User", email: email);
      return true;
    }
    return false;
  }

  void register(String username, String email, String password) {
    _currentUser = User(id: "1", username: username, email: email);
  }

  void logout() {
    _currentUser = null;
  }
}
