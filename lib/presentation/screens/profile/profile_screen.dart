import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/config/firebase_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../providers/activity_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notes_provider.dart';
import '../../providers/todos_provider.dart';
import '../../routes/app_routes.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgCanvas,
      appBar: AppBar(
        title: const Text('Hồ Sơ & Nhật Ký Hệ Thống'),
        actions: [
          IconButton(
            tooltip: 'Đăng xuất',
            icon: const Icon(Icons.logout_rounded, color: AppColors.error),
            onPressed: () => _confirmLogout(context),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // User Card
            Consumer<AuthProvider>(
              builder: (context, auth, _) {
                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: AppColors.primaryLight,
                        child: const Icon(Icons.person, size: 36, color: AppColors.primary),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              auth.currentUser?.email ?? 'user@cuongtt.vn',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'UID: ${auth.currentUser?.id ?? "local_uid"}',
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontFamily: 'monospace'),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: FirebaseConfig.isFirebaseReady ? Colors.green.withAlpha(20) : Colors.orange.withAlpha(20),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                FirebaseConfig.isFirebaseReady ? 'Firebase Connected (cuongtt-e83bf)' : 'Dev Mock Mode',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: FirebaseConfig.isFirebaseReady ? Colors.green : Colors.orange,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 20),

            // 6 Tables Architecture Summary Card (For Graduation Defense)
            const Text(
              '📦 Kiến Trúc 7 Bảng Database (Cloud Firestore & RBAC)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 10),
            Consumer3<NotesProvider, TodosProvider, ActivityProvider>(
              builder: (context, notes, todos, activity, _) {
                return GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 2.3,
                  children: [
                    _tableItem('1. users', 'Hồ sơ tài khoản', Icons.people_outline, Colors.blue),
                    _tableItem('2. notes', '${notes.notes.length} ghi chú', Icons.note_alt_outlined, Colors.purple),
                    _tableItem('3. categories', 'Danh mục phân loại', Icons.folder_open_rounded, Colors.indigo),
                    _tableItem('4. todos', '${todos.todos.length} công việc', Icons.checklist_rounded, Colors.teal),
                    _tableItem('5. teams', 'Nhóm & phân quyền', Icons.groups_rounded, Colors.pink),
                    _tableItem('6. game_scores', 'Điểm mini-games', Icons.videogame_asset_outlined, Colors.deepOrange),
                    _tableItem('7. activity_logs', '${activity.logs.length} nhật ký', Icons.history_rounded, Colors.brown),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),

            // Live Activity Log
            const Text(
              '⏱ Nhật Ký Hoạt Động (activity_logs)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 10),
            Consumer<ActivityProvider>(
              builder: (context, activity, _) {
                if (activity.logs.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Center(
                      child: Text('Chưa có hoạt động nào được ghi nhận', style: TextStyle(color: AppColors.textSecondary)),
                    ),
                  );
                }
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: activity.logs.length,
                    separatorBuilder: (_, _) => const Divider(height: 1, color: AppColors.border),
                    itemBuilder: (context, index) {
                      final log = activity.logs[index];
                      return ListTile(
                        dense: true,
                        leading: const Icon(Icons.radio_button_checked, size: 14, color: AppColors.primary),
                        title: Text(log.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        subtitle: Text(
                          DateTime.fromMillisecondsSinceEpoch(log.createdAt).toString().substring(0, 16),
                          style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _tableItem(String name, String desc, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 22, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Text(desc, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Đăng Xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất khỏi tài khoản?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<AuthProvider>().logout();
              if (context.mounted) {
                context.read<NotesProvider>().syncUser(null);
                context.read<TodosProvider>().syncUser(null);
                Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (r) => false);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Đăng Xuất'),
          ),
        ],
      ),
    );
  }
}
