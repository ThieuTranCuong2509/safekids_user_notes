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

  void seedInitialIfEmpty(String userId) {
    // Seed starter notes for actual user or demo accounts if empty
    if (userId.contains('cuong') || userId.contains('demo') || userId.contains('admin')) {
      if (!_userNotes.containsKey(userId) || _userNotes[userId]!.isEmpty) {
        final now = DateTime.now().millisecondsSinceEpoch;
        _userNotes[userId] = [
          NoteEntity(
            id: 'note_welcome',
            userId: userId,
            title: 'Chào mừng bạn đến với Cuong Tran Notes! 👋',
            content: 'Đây là ứng dụng ghi chú cá nhân & làm việc nhóm đa nền tảng kết hợp Cloud Firestore, Todo Checklist và Mini-Games.',
            categoryId: 'general',
            colorTag: '#FFF9C4',
            isPinned: true,
            createdAt: now - 3600000,
            updatedAt: now - 3600000,
          ),
          NoteEntity(
            id: 'note_thesis',
            userId: userId,
            title: 'Kế hoạch hoàn thành đồ án tốt nghiệp 🎓',
            content: '1. Kiểm tra cấu hình Firebase Authentication và Cloud Firestore.\n2. Thử nghiệm tính năng tạo nhóm và phân quyền thành viên (RBAC).\n3. Trải nghiệm game Flappy Bird 60 FPS.',
            categoryId: 'study',
            colorTag: '#E1F5FE',
            isPinned: true,
            createdAt: now - 7200000,
            updatedAt: now - 1800000,
          ),
          NoteEntity(
            id: 'note_tips',
            userId: userId,
            title: 'Tối ưu hiệu năng với Consumer trong Provider ⚡',
            content: 'Bọc Consumer quanh widget cần cập nhật để tránh rebuild toàn bộ màn hình, giúp ứng dụng đạt tốc độ phản hồi 60 FPS mượt mà.',
            categoryId: 'idea',
            colorTag: '#E8F5E9',
            isPinned: false,
            createdAt: now - 10000000,
            updatedAt: now - 10000000,
          ),
        ];
      }
    }
  }

  Stream<List<NoteEntity>> watchNotes(String userId) {
    seedInitialIfEmpty(userId);
    final ctrl = _getController(userId);
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
    await Future.delayed(const Duration(milliseconds: 10));
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
    await Future.delayed(const Duration(milliseconds: 10));
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
    await Future.delayed(const Duration(milliseconds: 10));
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
