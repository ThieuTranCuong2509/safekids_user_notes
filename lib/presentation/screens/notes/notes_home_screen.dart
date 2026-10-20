import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../../domain/models/note_entity.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notes_provider.dart';
import '../../providers/team_provider.dart';
import '../../routes/app_routes.dart';
import '../games/games_hub_screen.dart';
import '../profile/profile_screen.dart';
import '../teams/teams_screen.dart';
import '../todos/todos_screen.dart';
import 'widgets/note_card.dart';
import 'widgets/note_search_bar.dart';

class NotesHomeScreen extends StatefulWidget {
  const NotesHomeScreen({super.key});

  @override
  State<NotesHomeScreen> createState() => _NotesHomeScreenState();
}

class _NotesHomeScreenState extends State<NotesHomeScreen> {
  int _currentIndex = 0;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _confirmDelete(BuildContext context, NoteEntity note) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Delete Note'),
        content: Text('Are you sure you want to delete "${note.title.isNotEmpty ? note.title : 'Untitled'}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              context.read<NotesProvider>().deleteNote(note.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              minimumSize: const Size(80, 36),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesTab(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final notesProvider = context.watch<NotesProvider>();
    final teamProvider = context.watch<TeamProvider>();
    final notes = notesProvider.notes;

    return Scaffold(
      backgroundColor: AppColors.bgCanvas,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Cuong Tran Notes'),
            if (auth.currentUser?.email != null)
              Text(
                auth.currentUser!.email,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.normal,
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: teamProvider.canEditActiveTeam
            ? () {
                Navigator.pushNamed(context, AppRoutes.editor);
              }
            : null,
        icon: const Icon(Icons.add),
        label: const Text('New Note'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: NoteSearchBar(
                controller: _searchController,
                onChanged: (val) => notesProvider.setSearchQuery(val),
                onClear: () {
                  _searchController.clear();
                  notesProvider.clearSearch();
                },
              ),
            ),
            if (notesProvider.errorMessage != null)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.errorBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.error.withAlpha(80)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, size: 18, color: AppColors.error),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        notesProvider.errorMessage!,
                        style: const TextStyle(fontSize: 13, color: AppColors.error),
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: notesProvider.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                    )
                  : notes.isEmpty
                      ? EmptyStateView(
                          icon: _searchController.text.isNotEmpty
                              ? Icons.search_off_rounded
                              : Icons.sticky_note_2_outlined,
                          title: _searchController.text.isNotEmpty
                              ? 'No matching notes'
                              : 'No notes yet',
                          subtitle: _searchController.text.isNotEmpty
                              ? 'Try searching with a different keyword.'
                              : 'Tap the + button below to create your first real-time note.',
                          buttonText: _searchController.text.isNotEmpty ? null : 'Create Note',
                          onButtonPressed: () {
                            Navigator.pushNamed(context, AppRoutes.editor);
                          },
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          itemCount: notes.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 12),
                          itemBuilder: (ctx, index) {
                            final note = notes[index];
                            return NoteCard(
                              note: note,
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  AppRoutes.editor,
                                  arguments: note,
                                );
                              },
                              onDelete: () => _confirmDelete(context, note),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    switch (_currentIndex) {
      case 0:
        return _buildNotesTab(context);
      case 1:
        return const TodosScreen();
      case 2:
        return const TeamsScreen();
      case 3:
        return const GamesHubScreen();
      case 4:
        return const ProfileScreen();
      default:
        return _buildNotesTab(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildBody(context),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.notes_rounded),
            label: 'Ghi chú',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.checklist_rounded),
            label: 'Công việc',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.groups_rounded),
            label: 'Nhóm (RBAC)',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.sports_esports_rounded),
            label: 'Giải trí',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded),
            label: 'Hồ sơ',
          ),
        ],
      ),
    );
  }
}
