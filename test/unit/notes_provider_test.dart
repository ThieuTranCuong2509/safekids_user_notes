import 'package:flutter_test/flutter_test.dart';
import 'package:cuongtran_notes/data/repositories/notes_repository_impl.dart';
import 'package:cuongtran_notes/data/services/mock_notes_service.dart';
import 'package:cuongtran_notes/presentation/providers/notes_provider.dart';

void main() {
  group('NotesProvider', () {
    late MockNotesService mockNotesService;
    late NotesRepositoryImpl notesRepository;
    late NotesProvider notesProvider;

    setUp(() {
      mockNotesService = MockNotesService();
      notesRepository = NotesRepositoryImpl(mockService: mockNotesService);
      notesProvider = NotesProvider(notesRepository: notesRepository);
    });

    tearDown(() {
      notesProvider.dispose();
      mockNotesService.dispose();
    });

    test('initial state has empty notes and no user', () {
      expect(notesProvider.currentUserId, isNull);
      expect(notesProvider.notes, isEmpty);
      expect(notesProvider.isLoading, isFalse);
    });

    test('syncUser subscribes and receives notes in realtime', () async {
      notesProvider.syncUser('user_1');
      expect(notesProvider.currentUserId, 'user_1');

      // Create a note for user_1
      await notesProvider.createNote(
        title: 'First Note',
        content: 'Content of the first note',
      );

      // Wait for stream event to propagate
      await Future.delayed(const Duration(milliseconds: 50));

      expect(notesProvider.notes.length, 1);
      expect(notesProvider.notes.first.title, 'First Note');
      expect(notesProvider.notes.first.content, 'Content of the first note');
    });

    test('updateNote modifies content in realtime stream', () async {
      notesProvider.syncUser('user_1');
      await notesProvider.createNote(title: 'Original', content: 'Body');
      await Future.delayed(const Duration(milliseconds: 50));

      final noteId = notesProvider.notes.first.id;
      final updateSuccess = await notesProvider.updateNote(
        noteId: noteId,
        title: 'Edited Title',
        content: 'Edited Body',
      );

      expect(updateSuccess, isTrue);
      await Future.delayed(const Duration(milliseconds: 50));

      expect(notesProvider.notes.first.title, 'Edited Title');
      expect(notesProvider.notes.first.content, 'Edited Body');
    });

    test('deleteNote removes note from stream', () async {
      notesProvider.syncUser('user_1');
      await notesProvider.createNote(title: 'To Delete', content: 'Will be removed');
      await Future.delayed(const Duration(milliseconds: 50));

      expect(notesProvider.notes.length, 1);
      final noteId = notesProvider.notes.first.id;

      final deleteSuccess = await notesProvider.deleteNote(noteId);
      expect(deleteSuccess, isTrue);
      await Future.delayed(const Duration(milliseconds: 50));

      expect(notesProvider.notes, isEmpty);
    });

    test('search query filters notes accurately', () async {
      notesProvider.syncUser('user_1');
      await notesProvider.createNote(title: 'Flutter Dart', content: 'Mobile dev');
      await notesProvider.createNote(title: 'Firebase RTDB', content: 'Database sync');
      await Future.delayed(const Duration(milliseconds: 50));

      expect(notesProvider.notes.length, 2);

      // Search by title
      notesProvider.setSearchQuery('Dart');
      expect(notesProvider.notes.length, 1);
      expect(notesProvider.notes.first.title, 'Flutter Dart');

      // Search by content
      notesProvider.setSearchQuery('sync');
      expect(notesProvider.notes.length, 1);
      expect(notesProvider.notes.first.title, 'Firebase RTDB');

      // Clear search
      notesProvider.clearSearch();
      expect(notesProvider.notes.length, 2);
    });

    test('switching user isolates notes per user', () async {
      notesProvider.syncUser('user_A');
      await notesProvider.createNote(title: 'User A Note', content: 'Private to A');
      await Future.delayed(const Duration(milliseconds: 50));
      expect(notesProvider.notes.length, 1);

      // Switch to user_B
      notesProvider.syncUser('user_B');
      await Future.delayed(const Duration(milliseconds: 50));
      expect(notesProvider.notes, isEmpty);

      // Create note for B
      await notesProvider.createNote(title: 'User B Note', content: 'Private to B');
      await Future.delayed(const Duration(milliseconds: 50));
      expect(notesProvider.notes.length, 1);
      expect(notesProvider.notes.first.title, 'User B Note');

      // Switch back to A
      notesProvider.syncUser('user_A');
      await Future.delayed(const Duration(milliseconds: 50));
      expect(notesProvider.notes.length, 1);
      expect(notesProvider.notes.first.title, 'User A Note');
    });
  });
}
