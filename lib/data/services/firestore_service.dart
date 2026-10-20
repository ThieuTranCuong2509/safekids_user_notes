import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../domain/models/activity_log_entity.dart';
import '../../domain/models/category_entity.dart';
import '../../domain/models/game_score_entity.dart';
import '../../domain/models/note_entity.dart';
import '../../domain/models/team_entity.dart';
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
    try {
      await _usersCol.doc(user.id).set(user.toMap(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('[FirestoreService] saveUserProfile error: $e');
    }
  }

  Future<UserEntity?> getUserProfile(String userId) async {
    try {
      final doc = await _usersCol.doc(userId).get();
      if (!doc.exists || doc.data() == null) return null;
      return UserEntity.fromMap(doc.data()!);
    } catch (e) {
      debugPrint('[FirestoreService] getUserProfile error: $e');
      return null;
    }
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
      list.sort((a, b) {
        if (a.isPinned != b.isPinned) {
          return a.isPinned ? -1 : 1;
        }
        return b.updatedAt.compareTo(a.updatedAt);
      });
      return list;
    }).handleError((error) {
      debugPrint('[FirestoreService] watchNotes error (Firestore may not be created yet): $error');
      return <NoteEntity>[];
    });
  }

  Stream<List<NoteEntity>> watchTeamNotes(String teamId) {
    return _notesCol
        .where('teamId', isEqualTo: teamId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) {
        return NoteEntity.fromMap(doc.id, doc.data());
      }).toList();
      list.sort((a, b) {
        if (a.isPinned != b.isPinned) {
          return a.isPinned ? -1 : 1;
        }
        return b.updatedAt.compareTo(a.updatedAt);
      });
      return list;
    }).handleError((error) {
      debugPrint('[FirestoreService] watchTeamNotes error: $error');
      return <NoteEntity>[];
    });
  }

  Future<NoteEntity> createNote({
    required String userId,
    required String title,
    required String content,
    String categoryId = 'general',
    String colorTag = '#FFFFFF',
    bool isPinned = false,
    String? teamId,
    String? authorName,
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
      teamId: teamId,
      authorName: authorName,
      createdAt: now,
      updatedAt: now,
    );
    try {
      await doc.set(note.toMap());
      await logActivity(
        userId: userId,
        action: 'create_note',
        title: 'Tạo ghi chú: ${note.title.isNotEmpty ? note.title : "Không tiêu đề"}',
      );
    } catch (e) {
      debugPrint('[FirestoreService] createNote error: $e');
    }
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
    String? teamId,
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
    if (teamId != null) updateData['teamId'] = teamId;

    try {
      await _notesCol.doc(noteId).update(updateData);
      await logActivity(
        userId: userId,
        action: 'update_note',
        title: 'Cập nhật ghi chú: ${title.isNotEmpty ? title : "Không tiêu đề"}',
      );
    } catch (e) {
      debugPrint('[FirestoreService] updateNote error: $e');
    }
  }

  Future<void> deleteNote({
    required String userId,
    required String noteId,
  }) async {
    try {
      await _notesCol.doc(noteId).delete();
      await logActivity(
        userId: userId,
        action: 'delete_note',
        title: 'Xóa một ghi chú',
      );
    } catch (e) {
      debugPrint('[FirestoreService] deleteNote error: $e');
    }
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
    }).handleError((error) {
      debugPrint('[FirestoreService] watchCategories error: $error');
      return <CategoryEntity>[];
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
    try {
      await doc.set(cat.toMap());
    } catch (e) {
      debugPrint('[FirestoreService] createCategory error: $e');
    }
    return cat;
  }

  Future<void> deleteCategory(String categoryId) async {
    try {
      await _categoriesCol.doc(categoryId).delete();
    } catch (e) {
      debugPrint('[FirestoreService] deleteCategory error: $e');
    }
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
      list.sort((a, b) {
        if (a.isCompleted != b.isCompleted) {
          return a.isCompleted ? 1 : -1;
        }
        return b.createdAt.compareTo(a.createdAt);
      });
      return list;
    }).handleError((error) {
      debugPrint('[FirestoreService] watchTodos error: $error');
      return <TodoEntity>[];
    });
  }

  Stream<List<TodoEntity>> watchTeamTodos(String teamId) {
    return _todosCol
        .where('teamId', isEqualTo: teamId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) {
        return TodoEntity.fromMap(doc.id, doc.data());
      }).toList();
      list.sort((a, b) {
        if (a.isCompleted != b.isCompleted) {
          return a.isCompleted ? 1 : -1;
        }
        return b.createdAt.compareTo(a.createdAt);
      });
      return list;
    }).handleError((error) {
      debugPrint('[FirestoreService] watchTeamTodos error: $error');
      return <TodoEntity>[];
    });
  }

  Future<TodoEntity> createTodo({
    required String userId,
    required String title,
    String priority = 'medium',
    int? dueDate,
    String? teamId,
    String? assigneeName,
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
      teamId: teamId,
      assigneeName: assigneeName,
      createdAt: now,
      updatedAt: now,
    );
    try {
      await doc.set(todo.toMap());
      await logActivity(
        userId: userId,
        action: 'create_todo',
        title: 'Thêm công việc: ${todo.title}',
      );
    } catch (e) {
      debugPrint('[FirestoreService] createTodo error: $e');
    }
    return todo;
  }

  Future<void> toggleTodo(String todoId, bool isCompleted, String userId) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    try {
      await _todosCol.doc(todoId).update({
        'isCompleted': isCompleted,
        'updatedAt': now,
      });
      if (isCompleted) {
        await logActivity(
          userId: userId,
          action: 'complete_todo',
          title: 'Hoàn thành công việc',
        );
      }
    } catch (e) {
      debugPrint('[FirestoreService] toggleTodo error: $e');
    }
  }

  Future<void> deleteTodo(String todoId) async {
    try {
      await _todosCol.doc(todoId).delete();
    } catch (e) {
      debugPrint('[FirestoreService] deleteTodo error: $e');
    }
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
    }).handleError((error) {
      debugPrint('[FirestoreService] watchTopScores error: $error');
      return <GameScoreEntity>[];
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
    try {
      await doc.set(scoreEntry.toMap());
      final gameTitle = gameType == 'flappy_bird'
          ? 'Flappy Bird'
          : (gameType == 'memory_match' ? 'Memory Flip' : 'Math Blitz');
      await logActivity(
        userId: userId,
        action: 'play_game',
        title: 'Đạt $score điểm trong trò chơi $gameTitle',
      );
    } catch (e) {
      debugPrint('[FirestoreService] recordGameScore error: $e');
    }
  }

  // 6. Teams & Roles Collection
  CollectionReference<Map<String, dynamic>> get _teamsCol =>
      _firestore.collection('teams');

  Stream<List<TeamEntity>> watchUserTeams(String userId) {
    return _teamsCol
        .where('memberIds', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return TeamEntity.fromMap(doc.id, doc.data());
      }).toList();
    }).handleError((error) {
      debugPrint('[FirestoreService] watchUserTeams error: $error');
      return <TeamEntity>[];
    });
  }

  Future<TeamEntity> createTeam({
    required String ownerId,
    required String name,
    String description = '',
  }) async {
    final doc = _teamsCol.doc();
    final now = DateTime.now().millisecondsSinceEpoch;
    final team = TeamEntity(
      id: doc.id,
      name: name.trim(),
      description: description.trim(),
      ownerId: ownerId,
      memberIds: [ownerId],
      memberRoles: {ownerId: 'owner'},
      createdAt: now,
      updatedAt: now,
    );
    try {
      await doc.set(team.toMap());
      await logActivity(
        userId: ownerId,
        action: 'create_team',
        title: 'Tạo nhóm mới: ${team.name}',
      );
    } catch (e) {
      debugPrint('[FirestoreService] createTeam error: $e');
    }
    return team;
  }

  Future<void> updateMemberRole({
    required String teamId,
    required String memberId,
    required String role, // 'owner', 'editor', 'viewer'
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    try {
      await _teamsCol.doc(teamId).update({
        'memberRoles.$memberId': role,
        'updatedAt': now,
      });
    } catch (e) {
      debugPrint('[FirestoreService] updateMemberRole error: $e');
    }
  }

  Future<void> addMemberToTeam({
    required String teamId,
    required String memberId,
    String role = 'editor',
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    try {
      await _teamsCol.doc(teamId).update({
        'memberIds': FieldValue.arrayUnion([memberId]),
        'memberRoles.$memberId': role,
        'updatedAt': now,
      });
    } catch (e) {
      debugPrint('[FirestoreService] addMemberToTeam error: $e');
    }
  }

  Future<void> removeMemberFromTeam({
    required String teamId,
    required String memberId,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    try {
      await _teamsCol.doc(teamId).update({
        'memberIds': FieldValue.arrayRemove([memberId]),
        'memberRoles.$memberId': FieldValue.delete(),
        'updatedAt': now,
      });
    } catch (e) {
      debugPrint('[FirestoreService] removeMemberFromTeam error: $e');
    }
  }

  Future<void> deleteTeam(String teamId) async {
    try {
      await _teamsCol.doc(teamId).delete();
    } catch (e) {
      debugPrint('[FirestoreService] deleteTeam error: $e');
    }
  }

  // 7. Activity Logs Collection
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
    }).handleError((error) {
      debugPrint('[FirestoreService] watchActivityLogs error: $error');
      return <ActivityLogEntity>[];
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
    try {
      await doc.set(log.toMap());
    } catch (e) {
      debugPrint('[FirestoreService] logActivity error: $e');
    }
  }
}
