import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../domain/models/note_entity.dart';
import '../../domain/repositories/i_notes_repository.dart';

class NotesProvider extends ChangeNotifier {
  final INotesRepository notesRepository;
  StreamSubscription<List<NoteEntity>>? _subscription;

  String? _currentUserId;
  List<NoteEntity> _notes = [];
  String _searchQuery = '';
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;

  NotesProvider({required this.notesRepository});

  String? get currentUserId => _currentUserId;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;

  List<NoteEntity> get notes {
    if (_searchQuery.trim().isEmpty) {
      return _notes;
    }
    final q = _searchQuery.trim().toLowerCase();
    return _notes.where((n) {
      return n.title.toLowerCase().contains(q) ||
          n.content.toLowerCase().contains(q);
    }).toList();
  }

  static List<NoteEntity> _initialSeed(String userId) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return [
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

  void syncUser(String? userId) {
    if (_currentUserId == userId) return;

    _currentUserId = userId;
    _subscription?.cancel();
    _subscription = null;
    _searchQuery = '';

    if (userId == null || userId.isEmpty) {
      _notes = [];
      _isLoading = false;
      notifyListeners();
      return;
    }

    // Immediately seed for real/demo users so the UI never displays an empty dead screen
    if ((userId.contains('cuong') || userId.contains('demo') || userId.contains('admin')) && _notes.isEmpty) {
      _notes = _initialSeed(userId);
    }
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();

    _subscription = notesRepository.watchNotes(userId).listen(
      (newNotes) {
        _notes = List<NoteEntity>.from(newNotes);
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (err) {
        _errorMessage = _cleanError(err);
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void clearSearch() {
    if (_searchQuery.isNotEmpty) {
      _searchQuery = '';
      notifyListeners();
    }
  }

  Future<bool> createNote({
    required String title,
    required String content,
    String categoryId = 'general',
    String colorTag = '#FFFFFF',
    bool isPinned = false,
  }) async {
    if (_currentUserId == null) {
      _errorMessage = 'User not authenticated.';
      notifyListeners();
      return false;
    }

    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final note = await notesRepository.createNote(
        userId: _currentUserId!,
        title: title,
        content: content,
        categoryId: categoryId,
        colorTag: colorTag,
        isPinned: isPinned,
      );
      _notes = List<NoteEntity>.from(_notes);
      if (!_notes.any((n) => n.id == note.id)) {
        _notes.insert(0, note);
      }
      _isSaving = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _cleanError(e);
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateNote({
    required String noteId,
    required String title,
    required String content,
    String? categoryId,
    String? colorTag,
    bool? isPinned,
  }) async {
    if (_currentUserId == null) {
      _errorMessage = 'User not authenticated.';
      notifyListeners();
      return false;
    }

    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await notesRepository.updateNote(
        userId: _currentUserId!,
        noteId: noteId,
        title: title,
        content: content,
        categoryId: categoryId,
        colorTag: colorTag,
        isPinned: isPinned,
      );
      _notes = List<NoteEntity>.from(_notes);
      final idx = _notes.indexWhere((n) => n.id == noteId);
      if (idx != -1) {
        _notes[idx] = _notes[idx].copyWith(
          title: title,
          content: content,
          categoryId: categoryId,
          colorTag: colorTag,
          isPinned: isPinned,
          updatedAt: DateTime.now().millisecondsSinceEpoch,
        );
      }
      _isSaving = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _cleanError(e);
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteNote(String noteId) async {
    if (_currentUserId == null) {
      _errorMessage = 'User not authenticated.';
      notifyListeners();
      return false;
    }

    try {
      await notesRepository.deleteNote(
        userId: _currentUserId!,
        noteId: noteId,
      );
      _notes = List<NoteEntity>.from(_notes);
      _notes.removeWhere((n) => n.id == noteId);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _cleanError(e);
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  String _cleanError(dynamic error) {
    final str = error.toString();
    if (str.startsWith('Exception: ')) {
      return str.substring('Exception: '.length);
    }
    return str;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
