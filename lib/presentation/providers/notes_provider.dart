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

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    _subscription = notesRepository.watchNotes(userId).listen(
      (newNotes) {
        _notes = newNotes;
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
      await notesRepository.createNote(
        userId: _currentUserId!,
        title: title,
        content: content,
        categoryId: categoryId,
        colorTag: colorTag,
        isPinned: isPinned,
      );
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
