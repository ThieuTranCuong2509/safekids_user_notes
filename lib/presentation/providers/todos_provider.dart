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

  // Local fallback cache for mock/offline
  final List<TodoEntity> _localTodos = [];

  TodosProvider({required this.firestoreService});

  List<TodoEntity> get todos => _todos;
  bool get isLoading => _isLoading;
  int get completedCount => _todos.where((t) => t.isCompleted).length;
  int get pendingCount => _todos.where((t) => !t.isCompleted).length;

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

    if (FirebaseConfig.isFirebaseReady) {
      _isLoading = true;
      notifyListeners();
      _subscription = firestoreService.watchTodos(userId).listen(
        (list) {
          _todos = list;
          _isLoading = false;
          notifyListeners();
        },
        onError: (_) {
          _isLoading = false;
          _todos = List.from(_localTodos);
          notifyListeners();
        },
      );
    } else {
      // Dev mock initial seed if empty
      if (_localTodos.isEmpty) {
        final now = DateTime.now().millisecondsSinceEpoch;
        _localTodos.addAll([
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
        ]);
      }
      _todos = List.from(_localTodos);
      notifyListeners();
    }
  }

  Future<void> addTodo({required String title, String priority = 'medium'}) async {
    if (_userId == null || title.trim().isEmpty) return;

    if (FirebaseConfig.isFirebaseReady) {
      await firestoreService.createTodo(
        userId: _userId!,
        title: title.trim(),
        priority: priority,
      );
    } else {
      final now = DateTime.now().millisecondsSinceEpoch;
      final newTodo = TodoEntity(
        id: 'mock_t_$now',
        userId: _userId!,
        title: title.trim(),
        priority: priority,
        createdAt: now,
        updatedAt: now,
      );
      _localTodos.insert(0, newTodo);
      _todos = List.from(_localTodos);
      notifyListeners();
    }
  }

  Future<void> toggleTodo(String todoId, bool isCompleted) async {
    if (_userId == null) return;

    if (FirebaseConfig.isFirebaseReady) {
      await firestoreService.toggleTodo(todoId, isCompleted, _userId!);
    } else {
      final index = _localTodos.indexWhere((t) => t.id == todoId);
      if (index != -1) {
        _localTodos[index] = _localTodos[index].copyWith(
          isCompleted: isCompleted,
          updatedAt: DateTime.now().millisecondsSinceEpoch,
        );
        _todos = List.from(_localTodos);
        notifyListeners();
      }
    }
  }

  Future<void> deleteTodo(String todoId) async {
    if (FirebaseConfig.isFirebaseReady) {
      await firestoreService.deleteTodo(todoId);
    } else {
      _localTodos.removeWhere((t) => t.id == todoId);
      _todos = List.from(_localTodos);
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
