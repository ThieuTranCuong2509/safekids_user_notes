import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../domain/models/todo_entity.dart';
import '../../data/services/firestore_service.dart';
import '../../core/config/firebase_config.dart';

class TodosProvider extends ChangeNotifier {
  final FirestoreService firestoreService;
  StreamSubscription<List<TodoEntity>>? _subscription;

  String? _userId;
  List<TodoEntity> _todos = [];
  bool _isLoading = false;

  final List<TodoEntity> _localTodos = [];

  TodosProvider({required this.firestoreService});

  List<TodoEntity> get todos => _todos;
  bool get isLoading => _isLoading;
  int get completedCount => _todos.where((t) => t.isCompleted).length;
  int get pendingCount => _todos.where((t) => !t.isCompleted).length;

  static List<TodoEntity> _generateSeed(String userId) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return [
      TodoEntity(
        id: 'mock_t1',
        userId: userId,
        title: 'Hoàn thành báo cáo đồ án tốt nghiệp',
        priority: 'high',
        isCompleted: false,
        createdAt: now - 3600000,
        updatedAt: now - 3600000,
      ),
      TodoEntity(
        id: 'mock_t2',
        userId: userId,
        title: 'Cấu hình Firestore Database và Authentication',
        priority: 'high',
        isCompleted: true,
        createdAt: now - 7200000,
        updatedAt: now - 1800000,
      ),
      TodoEntity(
        id: 'mock_t3',
        userId: userId,
        title: 'Thử nghiệm tính năng Mini-game giải trí',
        priority: 'medium',
        isCompleted: false,
        createdAt: now - 1000000,
        updatedAt: now - 1000000,
      ),
    ];
  }

  void syncUser(String? userId) {
    if (_userId == userId) return;
    _userId = userId;
    _subscription?.cancel();
    _subscription = null;

    if (userId == null || userId.isEmpty) {
      _todos = [];
      notifyListeners();
      return;
    }

    if (_localTodos.isEmpty) {
      _localTodos.addAll(_generateSeed(userId));
    }
    _todos = List.from(_localTodos);
    _isLoading = false;
    notifyListeners();

    if (FirebaseConfig.isFirebaseReady) {
      _subscription = firestoreService.watchTodos(userId).listen(
        (list) {
          if (list.isNotEmpty) {
            _todos = list;
          }
          _isLoading = false;
          notifyListeners();
        },
        onError: (_) {
          _isLoading = false;
          if (_todos.isEmpty) {
            _todos = List.from(_localTodos);
          }
          notifyListeners();
        },
      );
    }
  }

  Future<void> addTodo({required String title, String priority = 'medium'}) async {
    if (_userId == null || title.trim().isEmpty) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    final newTodo = TodoEntity(
      id: 'todo_$now',
      userId: _userId!,
      title: title.trim(),
      priority: priority,
      createdAt: now,
      updatedAt: now,
    );

    // Optimistic UI update: instant 0ms feedback
    _todos.insert(0, newTodo);
    _localTodos.insert(0, newTodo);
    notifyListeners();

    if (FirebaseConfig.isFirebaseReady) {
      try {
        await firestoreService.createTodo(
          userId: _userId!,
          title: title.trim(),
          priority: priority,
        );
      } catch (_) {}
    }
  }

  Future<void> toggleTodo(String todoId, bool isCompleted) async {
    if (_userId == null) return;

    // Optimistic UI update
    final index = _todos.indexWhere((t) => t.id == todoId);
    if (index != -1) {
      _todos[index] = _todos[index].copyWith(
        isCompleted: isCompleted,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      );
      notifyListeners();
    }

    final localIdx = _localTodos.indexWhere((t) => t.id == todoId);
    if (localIdx != -1) {
      _localTodos[localIdx] = _localTodos[localIdx].copyWith(
        isCompleted: isCompleted,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      );
    }

    if (FirebaseConfig.isFirebaseReady) {
      try {
        await firestoreService.toggleTodo(todoId, isCompleted, _userId!);
      } catch (_) {}
    }
  }

  Future<void> deleteTodo(String todoId) async {
    _todos.removeWhere((t) => t.id == todoId);
    _localTodos.removeWhere((t) => t.id == todoId);
    notifyListeners();

    if (FirebaseConfig.isFirebaseReady) {
      try {
        await firestoreService.deleteTodo(todoId);
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
