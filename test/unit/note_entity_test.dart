import 'package:flutter_test/flutter_test.dart';
import 'package:cuongtran_notes/domain/models/note_entity.dart';

void main() {
  group('NoteEntity', () {
    test('serializes toMap and deserializes fromMap correctly', () {
      final now = DateTime.now().millisecondsSinceEpoch;
      final note = NoteEntity(
        id: 'note_123',
        userId: 'user_456',
        title: 'Meeting Notes',
        content: 'Review Cloud Notes architecture',
        createdAt: now,
        updatedAt: now,
      );

      final map = note.toMap();
      expect(map['id'], 'note_123');
      expect(map['userId'], 'user_456');
      expect(map['title'], 'Meeting Notes');
      expect(map['content'], 'Review Cloud Notes architecture');
      expect(map['createdAt'], now);
      expect(map['updatedAt'], now);

      final reconstructed = NoteEntity.fromMap('note_123', map);
      expect(reconstructed, equals(note));
    });

    test('copyWith updates properties while retaining others', () {
      final note = NoteEntity(
        id: 'n1',
        userId: 'u1',
        title: 'Original Title',
        content: 'Original Content',
        createdAt: 1000,
        updatedAt: 1000,
      );

      final updated = note.copyWith(
        title: 'Updated Title',
        updatedAt: 2000,
      );

      expect(updated.id, 'n1');
      expect(updated.userId, 'u1');
      expect(updated.title, 'Updated Title');
      expect(updated.content, 'Original Content');
      expect(updated.createdAt, 1000);
      expect(updated.updatedAt, 2000);
    });

    test('equality and hashCode match identical values', () {
      final noteA = NoteEntity(
        id: 'n1',
        userId: 'u1',
        title: 'Title',
        content: 'Content',
        createdAt: 100,
        updatedAt: 200,
      );

      final noteB = NoteEntity(
        id: 'n1',
        userId: 'u1',
        title: 'Title',
        content: 'Content',
        createdAt: 100,
        updatedAt: 200,
      );

      expect(noteA, equals(noteB));
      expect(noteA.hashCode, equals(noteB.hashCode));
    });
  });
}
