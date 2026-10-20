import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/models/user_entity.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth;

  FirebaseAuthService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  Stream<UserEntity?> get authStateChanges {
    return _auth.authStateChanges().map(_mapFirebaseUser);
  }

  UserEntity? get currentUser => _mapFirebaseUser(_auth.currentUser);

  Future<UserEntity> login({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw Exception('User authentication failed: empty user returned');
      }
      return _mapFirebaseUser(user)!;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<UserEntity> register({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw Exception('Account creation failed: empty user returned');
      }
      return _mapFirebaseUser(user)!;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  UserEntity? _mapFirebaseUser(User? user) {
    if (user == null) return null;
    return UserEntity(
      id: user.uid,
      email: user.email ?? '',
      displayName: user.displayName,
    );
  }

  Exception _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return Exception('No account found for that email address.');
      case 'wrong-password':
      case 'invalid-credential':
        return Exception('Incorrect password or credentials.');
      case 'email-already-in-use':
        return Exception('An account already exists for that email.');
      case 'weak-password':
        return Exception('The password provided is too weak.');
      case 'invalid-email':
        return Exception('The email address is badly formatted.');
      case 'network-request-failed':
        return Exception('Lỗi kết nối mạng. Vui lòng kiểm tra lại đường truyền.');
      case 'configuration-not-found':
        return Exception('Chưa kích hoạt Authentication trên Firebase Console! Vào Build > Authentication > Sign-in method và bật Email/Password.');
      default:
        if (e.message != null && e.message!.contains('CONFIGURATION_NOT_FOUND')) {
          return Exception('Chưa bật Email/Password trên Firebase Console (cuongtt-e83bf)! Vào Build > Authentication > Sign-in method và bật Email/Password.');
        }
        return Exception(e.message ?? 'Đã xảy ra lỗi xác thực.');
    }
  }
}
