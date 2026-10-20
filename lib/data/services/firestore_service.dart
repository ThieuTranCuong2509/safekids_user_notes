import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/activity_log_entity.dart';
import '../../domain/models/category_entity.dart';
import '../../domain/models/game_score_entity.dart';
import '../../domain/models/note_entity.dart';
import '../../domain/models/todo_entity.dart';
import '../../domain/models/user_entity.dart';

class FirestoreService {
  final FirebaseFirestore _firestore;

  FirestoreService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // 1. Users Collection
  CollectionReference<Map<String, dynamic>> get _usersCol =>
      _firestore.collection('users');

  Future<void> saveUserProfile(UserEntity user) async {
    await _usersCol.doc(user.id).set(user.toMap(), SetOptions(merge: true));
  }

  Future<UserEntity?> getUserProfile(String userId) async {
    final doc = await _usersCol.doc(userId).get();
    if (!doc.exists || doc.data() == null) return null;
    return UserEntity.fromMap(doc.data()!);
  }

  // 2. Notes Collection
  CollectionReference<Map<String, dynamic>> get _notesCol =>
      _firestore.collection('notes');

  Stream<List<NoteEntity>> watchNotes(String userId) {
    return _notesCol
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) {
        return NoteEntity.fromMap(doc.id, doc.data());
      }).toList();
      // Sort pinned first, then latest updated
      list.sort((a, b) {
        if (a.isPinned != b.isPinned) {
          return a.isPinned ? -1 : 1;
        }
        return b.updatedAt.compareTo(a.updatedAt);
      });
      return list;
    });
  }

  Future<NoteEntity> createNote({
    required String userId,
    required String title,
    required String content,
    String categoryId = 'general',
    String colorTag = '#FFFFFF',
    bool isPinned = false,
  }) async {
    final doc = _notesCol.doc();
    final now = DateTime.now().millisecondsSinceEpoch;
    final note = NoteEntity(
      id: doc.id,
      userId: userId,
      title: title.trim(),
      content: content.trim(),
      categoryId: categoryId,
      colorTag: colorTag,
      isPinned: isPinned,
      createdAt: now,
      updatedAt: now,
    );
    await doc.set(note.toMap());
    await logActivity(
      userId: userId,
      action: 'create_note',
      title: 'Created note: ${note.title.isNotEmpty ? note.title : "Untitled"}',
    );
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
    final now = DateTime.now().millisecondsSinceEpoch;
    final Map<String, dynamic> updateData = {
      'title': title.trim(),
      'content': content.trim(),
      'updatedAt': now,
    };
    if (categoryId != null) updateData['categoryId'] = categoryId;
    if (colorTag != null) updateData['colorTag'] = colorTag;
    if (isPinned != null) updateData['isPinned'] = isPinned;

    await _notesCol.doc(noteId).update(updateData);
    await logActivity(
      userId: userId,
      action: 'update_note',
      title: 'Updated note: ${title.isNotEmpty ? title : "Untitled"}',
    );
  }

  Future<void> deleteNote({
    required String userId,
    required String noteId,
  }) async {
    await _notesCol.doc(noteId).delete();
    await logActivity(
      userId: userId,
      action: 'delete_note',
      title: 'Deleted a note',
    );
  }

  // 3. Categories Collection
  CollectionReference<Map<String, dynamic>> get _categoriesCol =>
      _firestore.collection('categories');

  Stream<List<CategoryEntity>> watchCategories(String userId) {
    return _categoriesCol
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return CategoryEntity.fromMap(doc.id, doc.data());
      }).toList();
    });
  }

  Future<CategoryEntity> createCategory({
    required String userId,
    required String name,
    String colorHex = '#2196F3',
    String iconName = 'folder',
  }) async {
    final doc = _categoriesCol.doc();
    final now = DateTime.now().millisecondsSinceEpoch;
    final cat = CategoryEntity(
      id: doc.id,
      userId: userId,
      name: name.trim(),
      colorHex: colorHex,
      iconName: iconName,
      createdAt: now,
    );
    await doc.set(cat.toMap());
    return cat;
  }

  Future<void> deleteCategory(String categoryId) async {
    await _categoriesCol.doc(categoryId).delete();
  }

  // 4. Todos Collection
  CollectionReference<Map<String, dynamic>> get _todosCol =>
      _firestore.collection('todos');

  Stream<List<TodoEntity>> watchTodos(String userId) {
    return _todosCol
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) {
        return TodoEntity.fromMap(doc.id, doc.data());
      }).toList();
      // Sort incomplete first, then by priority/createdAt
      list.sort((a, b) {
        if (a.isCompleted != b.isCompleted) {
          return a.isCompleted ? 1 : -1;
        }
        return b.createdAt.compareTo(a.createdAt);
      });
      return list;
    });
  }

  Future<TodoEntity> createTodo({
    required String userId,
    required String title,
    String priority = 'medium',
    int? dueDate,
  }) async {
    final doc = _todosCol.doc();
    final now = DateTime.now().millisecondsSinceEpoch;
    final todo = TodoEntity(
      id: doc.id,
      userId: userId,
      title: title.trim(),
      isCompleted: false,
      priority: priority,
      dueDate: dueDate,
      createdAt: now,
      updatedAt: now,
    );
    await doc.set(todo.toMap());
    await logActivity(
      userId: userId,
      action: 'create_todo',
      title: 'Added todo: ${todo.title}',
    );
    return todo;
  }

  Future<void> toggleTodo(String todoId, bool isCompleted, String userId) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await _todosCol.doc(todoId).update({
      'isCompleted': isCompleted,
      'updatedAt': now,
    });
    if (isCompleted) {
      await logActivity(
        userId: userId,
        action: 'complete_todo',
        title: 'Completed a task',
      );
    }
  }

  Future<void> deleteTodo(String todoId) async {
    await _todosCol.doc(todoId).delete();
  }

  // 5. Game Scores (Leaderboard) Collection
  CollectionReference<Map<String, dynamic>> get _scoresCol =>
      _firestore.collection('game_scores');

  Stream<List<GameScoreEntity>> watchTopScores(String gameType) {
    return _scoresCol
        .where('gameType', isEqualTo: gameType)
        .limit(20)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) {
        return GameScoreEntity.fromMap(doc.id, doc.data());
      }).toList();
      list.sort((a, b) => b.score.compareTo(a.score));
      return list;
    });
  }

  Future<void> recordGameScore({
    required String userId,
    required String userName,
    required String gameType,
    required int score,
    required int timeSpentSeconds,
    String difficulty = 'normal',
  }) async {
    final doc = _scoresCol.doc();
    final now = DateTime.now().millisecondsSinceEpoch;
    final scoreEntry = GameScoreEntity(
      id: doc.id,
      userId: userId,
      userName: userName,
      gameType: gameType,
      score: score,
      timeSpentSeconds: timeSpentSeconds,
      difficulty: difficulty,
      createdAt: now,
    );
    await doc.set(scoreEntry.toMap());
    await logActivity(
      userId: userId,
      action: 'play_game',
      title: 'Scored $score in ${gameType == "memory_match" ? "Memory Flip" : "Math Blitz"}',
    );
  }

  // 6. Activity Logs Collection
  CollectionReference<Map<String, dynamic>> get _logsCol =>
      _firestore.collection('activity_logs');

  Stream<List<ActivityLogEntity>> watchActivityLogs(String userId) {
    return _logsCol
        .where('userId', isEqualTo: userId)
        .limit(30)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) {
        return ActivityLogEntity.fromMap(doc.id, doc.data());
      }).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Future<void> logActivity({
    required String userId,
    required String action,
    required String title,
    String details = '',
  }) async {
    final doc = _logsCol.doc();
    final now = DateTime.now().millisecondsSinceEpoch;
    final log = ActivityLogEntity(
      id: doc.id,
      userId: userId,
      action: action,
      title: title,
      details: details,
      createdAt: now,
    );
    await doc.set(log.toMap());
  }
}
