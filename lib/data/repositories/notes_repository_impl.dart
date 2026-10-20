import '../../core/config/firebase_config.dart';
import '../../domain/models/note_entity.dart';
import '../../domain/repositories/i_notes_repository.dart';
import '../services/firestore_service.dart';
import '../services/mock_notes_service.dart';

class NotesRepositoryImpl implements INotesRepository {
  final FirestoreService? firestoreService;
  final MockNotesService mockService;

  NotesRepositoryImpl({
    this.firestoreService,
    MockNotesService? mockService,
  }) : mockService = mockService ?? MockNotesService();

  FirestoreService? get _activeFirestore {
    return (FirebaseConfig.isFirebaseReady && firestoreService != null)
        ? firestoreService
        : null;
  }

  @override
  Stream<List<NoteEntity>> watchNotes(String userId) {
    final fs = _activeFirestore;
    if (fs != null) {
      return fs.watchNotes(userId);
    }
    return mockService.watchNotes(userId);
  }

  @override
  Future<NoteEntity> createNote({
    required String userId,
    required String title,
    required String content,
    String categoryId = 'general',
    String colorTag = '#FFFFFF',
    bool isPinned = false,
  }) {
    final fs = _activeFirestore;
    if (fs != null) {
      return fs.createNote(
        userId: userId,
        title: title,
        content: content,
        categoryId: categoryId,
        colorTag: colorTag,
        isPinned: isPinned,
      );
    }
    return mockService.createNote(
      userId: userId,
      title: title,
      content: content,
      categoryId: categoryId,
      colorTag: colorTag,
      isPinned: isPinned,
    );
  }

  @override
  Future<void> updateNote({
    required String userId,
    required String noteId,
    required String title,
    required String content,
    String? categoryId,
    String? colorTag,
    bool? isPinned,
  }) {
    final fs = _activeFirestore;
    if (fs != null) {
      return fs.updateNote(
        userId: userId,
        noteId: noteId,
        title: title,
        content: content,
        categoryId: categoryId,
        colorTag: colorTag,
        isPinned: isPinned,
      );
    }
    return mockService.updateNote(
      userId: userId,
      noteId: noteId,
      title: title,
      content: content,
      categoryId: categoryId,
      colorTag: colorTag,
      isPinned: isPinned,
    );
  }

  @override
  Future<void> deleteNote({
    required String userId,
    required String noteId,
  }) {
    final fs = _activeFirestore;
    if (fs != null) {
      return fs.deleteNote(
        userId: userId,
        noteId: noteId,
      );
    }
    return mockService.deleteNote(
      userId: userId,
      noteId: noteId,
    );
  }
}
