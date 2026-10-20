import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../providers/todos_provider.dart';

class TodosScreen extends StatefulWidget {
  const TodosScreen({super.key});

  @override
  State<TodosScreen> createState() => _TodosScreenState();
}

class _TodosScreenState extends State<TodosScreen> {
  final _textController = TextEditingController();
  String _selectedPriority = 'medium';

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _showAddTodoDialog() {
    _textController.clear();
    _selectedPriority = 'medium';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Thêm Công Việc Mới (Firestore)',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _textController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Nhập nội dung công việc...',
                  filled: true,
                  fillColor: AppColors.bgCanvas,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Text('Mức độ ưu tiên: ', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(width: 8),
                  _priorityChip('low', 'Thấp', Colors.green, setModalState),
                  const SizedBox(width: 6),
                  _priorityChip('medium', 'Vừa', Colors.orange, setModalState),
                  const SizedBox(width: 6),
                  _priorityChip('high', 'Cao', Colors.red, setModalState),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  final text = _textController.text.trim();
                  if (text.isNotEmpty) {
                    context.read<TodosProvider>().addTodo(
                      title: text,
                      priority: _selectedPriority,
                    );
                    Navigator.pop(ctx);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Thêm Công Việc', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _priorityChip(String val, String label, Color color, StateSetter setModalState) {
    final isSelected = _selectedPriority == val;
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : color)),
      selected: isSelected,
      selectedColor: color,
      backgroundColor: color.withAlpha(20),
      onSelected: (selected) {
        if (selected) {
          setModalState(() => _selectedPriority = val);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgCanvas,
      appBar: AppBar(
        title: const Text('Nhiệm Vụ & Checklist (Todos)'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTodoDialog,
        backgroundColor: AppColors.primary,
        tooltip: 'Thêm công việc',
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Consumer<TodosProvider>(
                builder: (context, todosProvider, _) {
                  return Row(
                    children: [
                      _statBadge('Tổng số', '${todosProvider.todos.length}', AppColors.textPrimary),
                      const SizedBox(width: 8),
                      _statBadge('Chưa xong', '${todosProvider.pendingCount}', Colors.orange),
                      const SizedBox(width: 8),
                      _statBadge('Đã xong', '${todosProvider.completedCount}', Colors.green),
                    ],
                  );
                },
              ),
            ),
            const Divider(height: 1, color: AppColors.border),
            Expanded(
              child: Consumer<TodosProvider>(
                builder: (context, todosProvider, _) {
                  final todos = todosProvider.todos;
                  if (todos.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_outline_rounded, size: 54, color: AppColors.primary.withAlpha(100)),
                          const SizedBox(height: 12),
                          const Text(
                            'Chưa có công việc nào',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 4),
                          const Text('Nhấn + bên dưới để tạo công việc mới', style: TextStyle(fontSize: 12, color: AppColors.textTertiary)),
                        ],
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: todos.length,
                    itemBuilder: (context, index) {
                      final todo = todos[index];
                      final priorityColor = todo.priority == 'high'
                          ? Colors.red
                          : (todo.priority == 'medium' ? Colors.orange : Colors.green);

                      return Dismissible(
                        key: Key(todo.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.delete_outline, color: Colors.white),
                        ),
                        onDismissed: (_) {
                          context.read<TodosProvider>().deleteTodo(todo.id);
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            leading: Checkbox(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                              activeColor: AppColors.primary,
                              value: todo.isCompleted,
                              onChanged: (val) {
                                context.read<TodosProvider>().toggleTodo(todo.id, val ?? false);
                              },
                            ),
                            title: Text(
                              todo.title,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                decoration: todo.isCompleted ? TextDecoration.lineThrough : null,
                                color: todo.isCompleted ? AppColors.textTertiary : AppColors.textPrimary,
                              ),
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: priorityColor.withAlpha(20),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                todo.priority.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: priorityColor,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statBadge(String label, String count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Text(count, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}
