import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../data/services/firestore_service.dart';
import '../../domain/models/user_entity.dart';
import '../../domain/repositories/i_auth_repository.dart';

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

class AuthProvider extends ChangeNotifier {
  final IAuthRepository authRepository;
  final FirestoreService? firestoreService;
  StreamSubscription<UserEntity?>? _authSubscription;

  AuthStatus _status = AuthStatus.initial;
  UserEntity? _currentUser;
  UserEntity? _pending2FAUser;
  bool _needsTwoFactor = false;
  String? _errorMessage;

  AuthProvider({
    required this.authRepository,
    this.firestoreService,
  }) {
    _init();
  }

  AuthStatus get status => _status;
  UserEntity? get currentUser => _currentUser;
  UserEntity? get pending2FAUser => _pending2FAUser;
  bool get needsTwoFactor => _needsTwoFactor;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated && _currentUser != null;
  bool get isLoading => _status == AuthStatus.loading;

  void _init() {
    _authSubscription = authRepository.authStateChanges.listen(
      (user) async {
        if (_needsTwoFactor && _pending2FAUser != null) {
          return;
        }
        if (user != null) {
          if (firestoreService != null) {
            final profile = await firestoreService!.getUserProfile(user.id);
            _currentUser = profile ?? user;
          } else {
            _currentUser = user;
          }
          _status = AuthStatus.authenticated;
          _errorMessage = null;
        } else {
          _currentUser = null;
          _status = AuthStatus.unauthenticated;
        }
        notifyListeners();
      },
      onError: (err) {
        _errorMessage = err.toString();
        _status = AuthStatus.error;
        notifyListeners();
      },
    );
  }

  Future<bool> login({required String email, required String password}) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    _needsTwoFactor = false;
    _pending2FAUser = null;
    notifyListeners();

    try {
      final user = await authRepository.login(
        email: email,
        password: password,
      );

      // Check if user has 2FA enabled
      UserEntity activeProfile = user;
      if (firestoreService != null) {
        final profile = await firestoreService!.getUserProfile(user.id);
        if (profile != null) {
          activeProfile = profile;
        }
      }

      if (activeProfile.isTwoFactorEnabled &&
          activeProfile.twoFactorPin != null &&
          activeProfile.twoFactorPin!.isNotEmpty) {
        // Requires 2FA verification before granting login
        _pending2FAUser = activeProfile;
        _needsTwoFactor = true;
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return false;
      }

      _currentUser = activeProfile;
      _status = AuthStatus.authenticated;
      if (firestoreService != null) {
        await firestoreService!.saveUserProfile(
          activeProfile.copyWith(lastLoginAt: DateTime.now().millisecondsSinceEpoch),
        );
      }
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _cleanError(e);
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  Future<bool> verifyTwoFactorPin(String pin) async {
    if (_pending2FAUser == null) return false;
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 300));

    if (pin.trim() == _pending2FAUser!.twoFactorPin?.trim()) {
      _currentUser = _pending2FAUser;
      _pending2FAUser = null;
      _needsTwoFactor = false;
      _status = AuthStatus.authenticated;
      if (firestoreService != null && _currentUser != null) {
        await firestoreService!.saveUserProfile(
          _currentUser!.copyWith(lastLoginAt: DateTime.now().millisecondsSinceEpoch),
        );
      }
      notifyListeners();
      return true;
    } else {
      _errorMessage = 'Mã xác thực 2 lớp (PIN) không chính xác. Vui lòng kiểm tra lại!';
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  void cancelTwoFactor() {
    _pending2FAUser = null;
    _needsTwoFactor = false;
    _errorMessage = null;
    _status = AuthStatus.unauthenticated;
    authRepository.logout();
    notifyListeners();
  }

  Future<bool> enableTwoFactor(String pin) async {
    if (_currentUser == null) return false;
    final updated = _currentUser!.copyWith(
      isTwoFactorEnabled: true,
      twoFactorPin: pin.trim(),
    );
    _currentUser = updated;
    notifyListeners();
    if (firestoreService != null) {
      await firestoreService!.updateUser2FA(updated.id, true, pin.trim());
      await firestoreService!.logActivity(
        userId: updated.id,
        action: 'security_2fa_enabled',
        title: 'Kích hoạt bảo mật xác thực 2 lớp (2FA)',
      );
    }
    return true;
  }

  Future<bool> disableTwoFactor() async {
    if (_currentUser == null) return false;
    final updated = _currentUser!.copyWith(
      isTwoFactorEnabled: false,
      twoFactorPin: null,
    );
    _currentUser = updated;
    notifyListeners();
    if (firestoreService != null) {
      await firestoreService!.updateUser2FA(updated.id, false, null);
      await firestoreService!.logActivity(
        userId: updated.id,
        action: 'security_2fa_disabled',
        title: 'Tắt bảo mật xác thực 2 lớp (2FA)',
      );
    }
    return true;
  }

  Future<bool> register({required String email, required String password}) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    _needsTwoFactor = false;
    _pending2FAUser = null;
    notifyListeners();

    try {
      final user = await authRepository.register(
        email: email,
        password: password,
      );
      final profile = user.copyWith(
        createdAt: DateTime.now().millisecondsSinceEpoch,
        lastLoginAt: DateTime.now().millisecondsSinceEpoch,
      );
      _currentUser = profile;
      _status = AuthStatus.authenticated;
      if (firestoreService != null) {
        await firestoreService!.saveUserProfile(profile);
      }
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _cleanError(e);
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  Future<bool> sendPasswordResetEmail(String email) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      await authRepository.sendPasswordResetEmail(email.trim());
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _cleanError(e);
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _status = AuthStatus.loading;
    notifyListeners();

    try {
      await authRepository.logout();
      _currentUser = null;
      _pending2FAUser = null;
      _needsTwoFactor = false;
      _status = AuthStatus.unauthenticated;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = _cleanError(e);
      _status = AuthStatus.error;
    } finally {
      notifyListeners();
    }
  }

  void clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  String _cleanError(dynamic error) {
    final str = error.toString();
    if (str.startsWith('Exception: ')) {
      return str.substring('Exception: '.length);
    }
    return str;
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
