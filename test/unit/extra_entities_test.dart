import 'package:flutter_test/flutter_test.dart';
import 'package:cuongtran_notes/domain/models/todo_entity.dart';
import 'package:cuongtran_notes/domain/models/game_score_entity.dart';
import 'package:cuongtran_notes/domain/models/category_entity.dart';
import 'package:cuongtran_notes/domain/models/activity_log_entity.dart';
import 'package:cuongtran_notes/domain/models/team_entity.dart';

void main() {
  group('New Entities Serialization Tests', () {
    test('TodoEntity serializes and deserializes correctly', () {
      final now = DateTime.now().millisecondsSinceEpoch;
      final todo = TodoEntity(
        id: 't1',
        userId: 'u1',
        title: 'Review graduation slides',
        priority: 'high',
        isCompleted: true,
        createdAt: now,
        updatedAt: now,
      );

      final map = todo.toMap();
      expect(map['title'], 'Review graduation slides');
      expect(map['isCompleted'], isTrue);

      final fromMap = TodoEntity.fromMap('t1', map);
      expect(fromMap, equals(todo));
    });

    test('GameScoreEntity calculates score and serializes correctly', () {
      final now = DateTime.now().millisecondsSinceEpoch;
      final score = GameScoreEntity(
        id: 'g1',
        userId: 'u1',
        userName: 'Cuong Tran',
        gameType: 'flappy_bird',
        score: 950,
        timeSpentSeconds: 25,
        createdAt: now,
      );

      final map = score.toMap();
      expect(map['score'], 950);
      expect(map['gameType'], 'flappy_bird');

      final fromMap = GameScoreEntity.fromMap('g1', map);
      expect(fromMap, equals(score));
    });

    test('CategoryEntity serializes correctly', () {
      final now = DateTime.now().millisecondsSinceEpoch;
      final cat = CategoryEntity(
        id: 'c1',
        userId: 'u1',
        name: 'Học tập',
        colorHex: '#2196F3',
        createdAt: now,
      );

      final map = cat.toMap();
      expect(map['name'], 'Học tập');

      final fromMap = CategoryEntity.fromMap('c1', map);
      expect(fromMap, equals(cat));
    });

    test('ActivityLogEntity serializes correctly', () {
      final now = DateTime.now().millisecondsSinceEpoch;
      final log = ActivityLogEntity(
        id: 'l1',
        userId: 'u1',
        action: 'create_note',
        title: 'Tạo ghi chú mới',
        createdAt: now,
      );

      final map = log.toMap();
      expect(map['action'], 'create_note');

      final fromMap = ActivityLogEntity.fromMap('l1', map);
      expect(fromMap, equals(log));
    });

    test('TeamEntity verifies roles and permissions correctly', () {
      final now = DateTime.now().millisecondsSinceEpoch;
      final team = TeamEntity(
        id: 'team_1',
        name: 'Dev Team',
        ownerId: 'user_owner',
        memberIds: ['user_owner', 'user_editor', 'user_viewer'],
        memberRoles: {
          'user_owner': 'owner',
          'user_editor': 'editor',
          'user_viewer': 'viewer',
        },
        createdAt: now,
        updatedAt: now,
      );

      expect(team.isOwner('user_owner'), isTrue);
      expect(team.canEdit('user_owner'), isTrue);
      expect(team.canEdit('user_editor'), isTrue);
      expect(team.canEdit('user_viewer'), isFalse);
      expect(team.getRole('unknown_user'), 'viewer');

      final map = team.toMap();
      final fromMap = TeamEntity.fromMap('team_1', map);
      expect(fromMap, equals(team));
    });
  });
}
