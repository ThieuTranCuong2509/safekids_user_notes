import 'dart:async';
import '../../domain/models/user_entity.dart';

class MockAuthService {
  UserEntity? _currentUser;
  final _controller = StreamController<UserEntity?>.broadcast();

  final Map<String, String> _registeredUsers = {
    'demo@cuongtran.notes': 'password123',
  };

  MockAuthService({UserEntity? initialUser}) : _currentUser = initialUser;

  Stream<UserEntity?> get authStateChanges {
    // Emit current state immediately to new listeners
    Future.microtask(() => _controller.add(_currentUser));
    return _controller.stream;
  }

  UserEntity? get currentUser => _currentUser;

  Future<UserEntity> login({
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final cleanEmail = email.trim().toLowerCase();

    if (_registeredUsers.containsKey(cleanEmail) && _registeredUsers[cleanEmail] == password) {
      _currentUser = UserEntity(
        id: 'mock_user_${cleanEmail.replaceAll('@', '_').replaceAll('.', '_')}',
        email: cleanEmail,
        displayName: cleanEmail.split('@').first,
      );
      _controller.add(_currentUser);
      return _currentUser!;
    }

    if (!_registeredUsers.containsKey(cleanEmail)) {
      throw Exception('User not found. Please register first or use demo@cuongtran.notes / password123');
    }
    throw Exception('Incorrect password.');
  }

  Future<UserEntity> register({
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final cleanEmail = email.trim().toLowerCase();

    if (_registeredUsers.containsKey(cleanEmail)) {
      throw Exception('An account already exists for that email.');
    }

    if (password.length < 6) {
      throw Exception('Password must be at least 6 characters.');
    }

    _registeredUsers[cleanEmail] = password;
    _currentUser = UserEntity(
      id: 'mock_user_${cleanEmail.replaceAll('@', '_').replaceAll('.', '_')}',
      email: cleanEmail,
      displayName: cleanEmail.split('@').first,
    );
    _controller.add(_currentUser);
    return _currentUser!;
  }

  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 150));
    _currentUser = null;
    _controller.add(null);
  }

  void dispose() {
    _controller.close();
  }
}
