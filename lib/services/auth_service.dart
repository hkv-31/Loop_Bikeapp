import 'package:flutter/material.dart';
import '../models/models.dart';
import 'local_storage_service.dart';

class AuthService with ChangeNotifier {
  UserModel? _currentUser;
  bool _isLoading = false;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;

  Future<String?> signInWithName(String name) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Simulate network delay
      await Future.delayed(Duration(seconds: 1));

      // Create user with timestamp as ID
      final userId = 'user_${DateTime.now().millisecondsSinceEpoch}';
      _currentUser = UserModel(
        id: userId,
        name: name,
        email: '',
        createdAt: DateTime.now(),
      );

      // Save to local database
      final storage = LocalStorageService();
      await storage.saveUser(_currentUser!);

      _isLoading = false;
      notifyListeners();
      return null;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return 'Sign in failed: $e';
    }
  }

  Future<void> signOut() async {
    _currentUser = null;
    notifyListeners();
  }

  // Load user from storage if available
  Future<void> loadUserFromStorage() async {
    try {
      final storage = LocalStorageService();
      // For demo, load the first user if exists
      final users = await storage.getUser('demo_user');
      if (users != null) {
        _currentUser = users;
        notifyListeners();
      }
    } catch (e) {
      print('Error loading user: $e');
    }
  }
}