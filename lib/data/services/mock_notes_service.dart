import 'dart:async';
import '../../domain/models/note_entity.dart';

class MockNotesService {
  final Map<String, List<NoteEntity>> _userNotes = {};
  final Map<String, StreamController<List<NoteEntity>>> _controllers = {};

  StreamController<List<NoteEntity>> _getController(String userId) {
    return _controllers.putIfAbsent(userId, () {
      final ctrl = StreamController<List<NoteEntity>>.broadcast();
      return ctrl;
    });
  }

  void _notify(String userId) {
    final list = _userNotes[userId] ?? [];
    list.sort((a, b) {
      if (a.isPinned != b.isPinned) {
        return a.isPinned ? -1 : 1;
      }
      return b.updatedAt.compareTo(a.updatedAt);
    });
    if (_controllers.containsKey(userId)) {
      _controllers[userId]!.add(List.unmodifiable(list));
    }
  }

  Stream<List<NoteEntity>> watchNotes(String userId) {
    final ctrl = _getController(userId);
    // Seed initial list
    Future.microtask(() => _notify(userId));
    return ctrl.stream;
  }

  Future<NoteEntity> createNote({
    required String userId,
    required String title,
    required String content,
    String categoryId = 'general',
    String colorTag = '#FFFFFF',
    bool isPinned = false,
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final now = DateTime.now().millisecondsSinceEpoch;
    final note = NoteEntity(
      id: 'mock_note_${now}_${DateTime.now().microsecond}',
      userId: userId,
      title: title.trim(),
      content: content.trim(),
      categoryId: categoryId,
      colorTag: colorTag,
      isPinned: isPinned,
      createdAt: now,
      updatedAt: now,
    );

    final list = _userNotes.putIfAbsent(userId, () => []);
    list.add(note);
    _notify(userId);
    return note;
  }

  Future<void> updateNote({
    required String userId,
    required String noteId,
    required String title,
    required String content,
    String? categoryId,
    String? colorTag,
    bool? isPinned,
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final list = _userNotes[userId];
    if (list != null) {
      final index = list.indexWhere((n) => n.id == noteId);
      if (index != -1) {
        final existing = list[index];
        list[index] = existing.copyWith(
          title: title.trim(),
          content: content.trim(),
          categoryId: categoryId ?? existing.categoryId,
          colorTag: colorTag ?? existing.colorTag,
          isPinned: isPinned ?? existing.isPinned,
          updatedAt: DateTime.now().millisecondsSinceEpoch,
        );
        _notify(userId);
      }
    }
  }

  Future<void> deleteNote({
    required String userId,
    required String noteId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final list = _userNotes[userId];
    if (list != null) {
      list.removeWhere((n) => n.id == noteId);
      _notify(userId);
    }
  }

  void dispose() {
    for (final ctrl in _controllers.values) {
      ctrl.close();
    }
    _controllers.clear();
  }
}
