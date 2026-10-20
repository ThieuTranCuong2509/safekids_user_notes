import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:cuongtran_notes/data/repositories/auth_repository_impl.dart';
import 'package:cuongtran_notes/data/repositories/notes_repository_impl.dart';
import 'package:cuongtran_notes/data/services/mock_auth_service.dart';
import 'package:cuongtran_notes/data/services/mock_notes_service.dart';
import 'package:cuongtran_notes/main.dart';
import 'package:cuongtran_notes/presentation/providers/auth_provider.dart';
import 'package:cuongtran_notes/presentation/providers/notes_provider.dart';
import 'package:cuongtran_notes/presentation/screens/auth/login_screen.dart';

void main() {
  testWidgets('App renders login screen when unauthenticated', (tester) async {
    final mockAuth = MockAuthService();
    final mockNotes = MockNotesService();

    final authRepo = AuthRepositoryImpl(mockService: mockAuth);
    final notesRepo = NotesRepositoryImpl(mockService: mockNotes);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>(
            create: (_) => AuthProvider(authRepository: authRepo),
          ),
          ChangeNotifierProxyProvider<AuthProvider, NotesProvider>(
            create: (_) => NotesProvider(notesRepository: notesRepo),
            update: (_, auth, notes) {
              notes ??= NotesProvider(notesRepository: notesRepo);
              notes.syncUser(auth.currentUser?.id);
              return notes;
            },
          ),
        ],
        child: const CuongTranNotesApp(),
      ),
    );

    // Initial render shows Splash
    expect(find.text('Cuong Tran Notes'), findsOneWidget);

    // Advance timer past splash delay
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    // Now LoginScreen is shown
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
  });
}
