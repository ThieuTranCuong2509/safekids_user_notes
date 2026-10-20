import 'package:flutter_test/flutter_test.dart';
import 'package:cuongtran_notes/data/repositories/auth_repository_impl.dart';
import 'package:cuongtran_notes/data/services/mock_auth_service.dart';
import 'package:cuongtran_notes/presentation/providers/auth_provider.dart';

void main() {
  group('AuthProvider', () {
    late MockAuthService mockAuthService;
    late AuthRepositoryImpl authRepository;
    late AuthProvider authProvider;

    setUp(() {
      mockAuthService = MockAuthService();
      authRepository = AuthRepositoryImpl(mockService: mockAuthService);
      authProvider = AuthProvider(authRepository: authRepository);
    });

    tearDown(() {
      authProvider.dispose();
      mockAuthService.dispose();
    });

    test('initial state defaults properly', () async {
      await Future.delayed(const Duration(milliseconds: 10));
      expect(authProvider.isAuthenticated, isFalse);
      expect(authProvider.currentUser, isNull);
    });

    test('login with valid demo credentials succeeds', () async {
      final result = await authProvider.login(
        email: 'demo@cuongtran.notes',
        password: 'password123',
      );

      expect(result, isTrue);
      expect(authProvider.isAuthenticated, isTrue);
      expect(authProvider.currentUser?.email, 'demo@cuongtran.notes');
      expect(authProvider.errorMessage, isNull);
    });

    test('login with invalid credentials fails with descriptive error', () async {
      final result = await authProvider.login(
        email: 'wrong@cuongtran.notes',
        password: 'wrongpassword',
      );

      expect(result, isFalse);
      expect(authProvider.isAuthenticated, isFalse);
      expect(authProvider.status, AuthStatus.error);
      expect(authProvider.errorMessage, isNotNull);
    });

    test('register with valid details creates user session', () async {
      final result = await authProvider.register(
        email: 'newuser@cuongtran.notes',
        password: 'securePassword123',
      );

      expect(result, isTrue);
      expect(authProvider.isAuthenticated, isTrue);
      expect(authProvider.currentUser?.email, 'newuser@cuongtran.notes');
    });

    test('register with weak password fails validation', () async {
      final result = await authProvider.register(
        email: 'short@cuongtran.notes',
        password: '123',
      );

      expect(result, isFalse);
      expect(authProvider.status, AuthStatus.error);
      expect(authProvider.errorMessage, contains('at least 6 characters'));
    });

    test('logout clears user state and flags unauthenticated', () async {
      // First login
      await authProvider.login(
        email: 'demo@cuongtran.notes',
        password: 'password123',
      );
      expect(authProvider.isAuthenticated, isTrue);

      // Now logout
      await authProvider.logout();
      expect(authProvider.isAuthenticated, isFalse);
      expect(authProvider.currentUser, isNull);
      expect(authProvider.status, AuthStatus.unauthenticated);
    });
  });
}
