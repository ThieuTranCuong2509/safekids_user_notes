import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/config/firebase_config.dart';
import 'core/theme/app_theme.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'data/repositories/notes_repository_impl.dart';
import 'data/services/firebase_auth_service.dart';
import 'data/services/firestore_service.dart';
import 'domain/repositories/i_auth_repository.dart';
import 'domain/repositories/i_notes_repository.dart';
import 'presentation/providers/activity_provider.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/games_provider.dart';
import 'presentation/providers/notes_provider.dart';
import 'presentation/providers/team_provider.dart';
import 'presentation/providers/todos_provider.dart';
import 'presentation/routes/app_routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase (falls back to dev mock mode if configuration is pending)
  await FirebaseConfig.initialize();

  final FirestoreService firestoreService = FirestoreService();

  final IAuthRepository authRepository = AuthRepositoryImpl(
    firebaseService: FirebaseAuthService(),
  );

  final INotesRepository notesRepository = NotesRepositoryImpl(
    firestoreService: firestoreService,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(authRepository: authRepository),
        ),
        ChangeNotifierProxyProvider<AuthProvider, NotesProvider>(
          create: (_) => NotesProvider(notesRepository: notesRepository),
          update: (_, auth, notes) {
            notes ??= NotesProvider(notesRepository: notesRepository);
            notes.syncUser(auth.currentUser?.id);
            return notes;
          },
        ),
        ChangeNotifierProxyProvider<AuthProvider, TodosProvider>(
          create: (_) => TodosProvider(firestoreService: firestoreService),
          update: (_, auth, todos) {
            todos ??= TodosProvider(firestoreService: firestoreService);
            todos.syncUser(auth.currentUser?.id);
            return todos;
          },
        ),
        ChangeNotifierProxyProvider<AuthProvider, GamesProvider>(
          create: (_) => GamesProvider(firestoreService: firestoreService),
          update: (_, auth, games) {
            games ??= GamesProvider(firestoreService: firestoreService);
            games.syncUser(auth.currentUser?.id, auth.currentUser?.displayName ?? auth.currentUser?.email.split('@').first);
            return games;
          },
        ),
        ChangeNotifierProxyProvider<AuthProvider, ActivityProvider>(
          create: (_) => ActivityProvider(firestoreService: firestoreService),
          update: (_, auth, activity) {
            activity ??= ActivityProvider(firestoreService: firestoreService);
            activity.syncUser(auth.currentUser?.id);
            return activity;
          },
        ),
        ChangeNotifierProxyProvider<AuthProvider, TeamProvider>(
          create: (_) => TeamProvider(firestoreService: firestoreService),
          update: (_, auth, teams) {
            teams ??= TeamProvider(firestoreService: firestoreService);
            teams.syncUser(auth.currentUser?.id);
            return teams;
          },
        ),
      ],
      child: const CuongTranNotesApp(),
    ),
  );
}

class CuongTranNotesApp extends StatelessWidget {
  const CuongTranNotesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cuong Tran Notes',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      initialRoute: AppRoutes.splash,
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
}
