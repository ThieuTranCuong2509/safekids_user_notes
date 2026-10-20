import 'package:firebase_database/firebase_database.dart';
import '../../domain/models/note_entity.dart';

class FirebaseNotesService {
  final FirebaseDatabase _database;

  FirebaseNotesService({FirebaseDatabase? database})
      : _database = database ?? FirebaseDatabase.instance;

  DatabaseReference _notesRef(String userId) =>
      _database.ref('users/$userId/notes');

  Stream<List<NoteEntity>> watchNotes(String userId) {
    return _notesRef(userId).onValue.map((event) {
      final snapshot = event.snapshot;
      if (!snapshot.exists || snapshot.value == null) {
        return <NoteEntity>[];
      }

      final dynamic rawValue = snapshot.value;
      final List<NoteEntity> notes = [];

      if (rawValue is Map) {
        rawValue.forEach((key, value) {
          if (value is Map) {
            notes.add(NoteEntity.fromMap(key.toString(), value));
          }
        });
      }

      // Sort by latest updated descending
      notes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return notes;
    });
  }

  Future<NoteEntity> createNote({
    required String userId,
    required String title,
    required String content,
  }) async {
    final ref = _notesRef(userId).push();
    final now = DateTime.now().millisecondsSinceEpoch;
    final note = NoteEntity(
      id: ref.key ?? now.toString(),
      userId: userId,
      title: title.trim(),
      content: content.trim(),
      createdAt: now,
      updatedAt: now,
    );

    await ref.set(note.toMap());
    return note;
  }

  Future<void> updateNote({
    required String userId,
    required String noteId,
    required String title,
    required String content,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await _notesRef(userId).child(noteId).update({
      'title': title.trim(),
      'content': content.trim(),
      'updatedAt': now,
    });
  }

  Future<void> deleteNote({
    required String userId,
    required String noteId,
  }) async {
    await _notesRef(userId).child(noteId).remove();
  }
}
