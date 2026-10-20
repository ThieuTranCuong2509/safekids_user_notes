import '../models/note_entity.dart';

abstract class INotesRepository {
  Stream<List<NoteEntity>> watchNotes(String userId);

  Future<NoteEntity> createNote({
    required String userId,
    required String title,
    required String content,
    String categoryId = 'general',
    String colorTag = '#FFFFFF',
    bool isPinned = false,
  });

  Future<void> updateNote({
    required String userId,
    required String noteId,
    required String title,
    required String content,
    String? categoryId,
    String? colorTag,
    bool? isPinned,
  });

  Future<void> deleteNote({
    required String userId,
    required String noteId,
  });
}
