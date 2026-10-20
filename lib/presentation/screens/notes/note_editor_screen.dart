import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/models/note_entity.dart';
import '../../providers/notes_provider.dart';

class NoteEditorScreen extends StatefulWidget {
  final NoteEntity? existingNote;

  const NoteEditorScreen({super.key, this.existingNote});

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  late bool _isPinned;
  late String _category;
  late String _colorTag;
  bool _hasChanges = false;

  bool get _isEditing => widget.existingNote != null;

  static const Map<String, String> _categories = {
    'general': 'Chung',
    'study': 'Học tập',
    'work': 'Công việc',
    'personal': 'Cá nhân',
    'idea': 'Ý tưởng',
  };

  static const List<String> _colors = [
    '#FFFFFF', // White
    '#FFF9C4', // Yellow
    '#E1F5FE', // Blue
    '#E8F5E9', // Green
    '#F3E5F5', // Purple
    '#FFEBEE', // Red
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.existingNote?.title ?? '');
    _contentController = TextEditingController(text: widget.existingNote?.content ?? '');
    _isPinned = widget.existingNote?.isPinned ?? false;
    _category = widget.existingNote?.categoryId ?? 'general';
    _colorTag = widget.existingNote?.colorTag ?? '#FFFFFF';

    _titleController.addListener(_markChanged);
    _contentController.addListener(_markChanged);
  }

  void _markChanged() {
    if (!_hasChanges) {
      setState(() => _hasChanges = true);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty && content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot save empty note.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final notesProvider = context.read<NotesProvider>();
    bool success;

    if (_isEditing) {
      success = await notesProvider.updateNote(
        noteId: widget.existingNote!.id,
        title: title,
        content: content,
        categoryId: _category,
        colorTag: _colorTag,
        isPinned: _isPinned,
      );
    } else {
      success = await notesProvider.createNote(
        title: title,
        content: content,
        categoryId: _category,
        colorTag: _colorTag,
        isPinned: _isPinned,
      );
    }

    if (success && mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _handleDelete() async {
    if (!_isEditing) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Note'),
        content: const Text('Are you sure you want to delete this note?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await context.read<NotesProvider>().deleteNote(widget.existingNote!.id);
      if (success && mounted) {
        Navigator.pop(context);
      }
    }
  }

  Color _hexToColor(String hex) {
    final buffer = StringBuffer();
    if (hex.length == 7) buffer.write('ff');
    buffer.write(hex.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = _hexToColor(_colorTag);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        title: Text(_isEditing ? 'Chỉnh sửa' : 'Ghi chú mới'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            tooltip: _isPinned ? 'Bỏ ghim' : 'Ghim ghi chú',
            icon: Icon(
              _isPinned ? Icons.push_pin : Icons.push_pin_outlined,
              color: _isPinned ? AppColors.primary : AppColors.textSecondary,
            ),
            onPressed: () {
              setState(() {
                _isPinned = !_isPinned;
                _hasChanges = true;
              });
            },
          ),
          Consumer<NotesProvider>(
            builder: (context, notesProvider, _) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isEditing)
                    IconButton(
                      tooltip: 'Xóa ghi chú',
                      icon: const Icon(Icons.delete_outline, color: AppColors.error),
                      onPressed: notesProvider.isSaving ? null : _handleDelete,
                    ),
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: TextButton.icon(
                      onPressed: notesProvider.isSaving ? null : _handleSave,
                      icon: notesProvider.isSaving
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                            )
                          : const Icon(Icons.check, size: 18),
                      label: Text(
                        notesProvider.isSaving ? 'Đang lưu...' : 'Lưu',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Category and Color Pickers Bar
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    // Categories
                    ..._categories.entries.map((e) {
                      final isSelected = _category == e.key;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(e.value, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : AppColors.textPrimary)),
                          selected: isSelected,
                          selectedColor: AppColors.primary,
                          backgroundColor: Colors.white.withAlpha(200),
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _category = e.key;
                                _hasChanges = true;
                              });
                            }
                          },
                        ),
                      );
                    }),
                    const SizedBox(width: 8),
                    // Colors
                    ..._colors.map((c) {
                      final isSelected = _colorTag == c;
                      final clr = _hexToColor(c);
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _colorTag = c;
                            _hasChanges = true;
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: clr,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? AppColors.primary : AppColors.border,
                              width: isSelected ? 2.5 : 1,
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _titleController,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.4,
                ),
                decoration: const InputDecoration(
                  hintText: 'Note Title',
                  hintStyle: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textTertiary,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const Divider(color: AppColors.border, height: 24),
              Expanded(
                child: TextField(
                  controller: _contentController,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.textPrimary,
                    height: 1.5,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Start typing note content...',
                    hintStyle: TextStyle(
                      fontSize: 16,
                      color: AppColors.textTertiary,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
