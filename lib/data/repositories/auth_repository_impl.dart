import '../../core/config/firebase_config.dart';
import '../../domain/models/user_entity.dart';
import '../../domain/repositories/i_auth_repository.dart';
import '../services/firebase_auth_service.dart';
import '../services/mock_auth_service.dart';

class AuthRepositoryImpl implements IAuthRepository {
  final FirebaseAuthService? firebaseService;
  final MockAuthService mockService;

  AuthRepositoryImpl({
    this.firebaseService,
    MockAuthService? mockService,
  }) : mockService = mockService ?? MockAuthService();

  FirebaseAuthService? get _activeFirebase {
    return (FirebaseConfig.isFirebaseReady && firebaseService != null)
        ? firebaseService
        : null;
  }

  @override
  Stream<UserEntity?> get authStateChanges {
    final fb = _activeFirebase;
    return fb != null ? fb.authStateChanges : mockService.authStateChanges;
  }

  @override
  UserEntity? get currentUser {
    final fb = _activeFirebase;
    return fb != null ? fb.currentUser : mockService.currentUser;
  }

  @override
  Future<UserEntity> login({
    required String email,
    required String password,
  }) {
    final fb = _activeFirebase;
    if (fb != null) {
      return fb.login(email: email, password: password);
    }
    return mockService.login(email: email, password: password);
  }

  @override
  Future<UserEntity> register({
    required String email,
    required String password,
  }) {
    final fb = _activeFirebase;
    if (fb != null) {
      return fb.register(email: email, password: password);
    }
    return mockService.register(email: email, password: password);
  }

  @override
  Future<void> logout() {
    final fb = _activeFirebase;
    if (fb != null) {
      return fb.logout();
    }
    return mockService.logout();
  }
}
