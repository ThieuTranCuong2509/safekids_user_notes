import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/config/firebase_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../../providers/activity_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/notes_provider.dart';
import '../../providers/team_provider.dart';
import '../../providers/todos_provider.dart';
import '../../routes/app_routes.dart';
import 'table_detail_screen.dart';
import 'tables_metadata.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _show2FADialog(BuildContext context, bool isCurrentlyEnabled) {
    final pinController = TextEditingController();
    final confirmPinController = TextEditingController();
    String? localError;
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
            contentPadding: const EdgeInsets.symmetric(horizontal: 24),
            actionsPadding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isCurrentlyEnabled ? Colors.red.withAlpha(20) : Colors.blue.withAlpha(20),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isCurrentlyEnabled ? Icons.lock_open_rounded : Icons.security_rounded,
                    color: isCurrentlyEnabled ? Colors.red : AppColors.primary,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    isCurrentlyEnabled ? 'Tắt Xác Thực 2 Lớp' : 'Kích Hoạt Bảo Mật 2FA',
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (isCurrentlyEnabled) ...[
                  const Text(
                    'Bạn có chắc chắn muốn tắt xác thực 2 lớp? Tài khoản sẽ chỉ cần mật khẩu thông thường để đăng nhập.',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                  ),
                ] else ...[
                  const Text(
                    'Thiết lập mã PIN bảo mật 6 số. Mỗi lần đăng nhập, bạn sẽ được yêu cầu nhập mã này để bảo vệ tài khoản khỏi truy cập trái phép.',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: pinController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    obscureText: true,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 20, letterSpacing: 8, fontFamily: 'monospace', fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      labelText: 'Mã PIN mới (6 chữ số)',
                      counterText: '',
                      hintText: '••••••',
                      filled: true,
                      fillColor: AppColors.bgSubtle,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: confirmPinController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    obscureText: true,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 20, letterSpacing: 8, fontFamily: 'monospace', fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      labelText: 'Nhập lại mã PIN xác nhận',
                      counterText: '',
                      hintText: '••••••',
                      filled: true,
                      fillColor: AppColors.bgSubtle,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
                if (localError != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    localError!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, color: AppColors.error, fontWeight: FontWeight.w600),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: isSaving ? null : () => Navigator.pop(dialogCtx),
                child: const Text('Hủy', style: TextStyle(color: AppColors.textSecondary)),
              ),
              ElevatedButton(
                onPressed: isSaving
                    ? null
                    : () async {
                        final auth = context.read<AuthProvider>();
                        if (isCurrentlyEnabled) {
                          setDialogState(() => isSaving = true);
                          await auth.disableTwoFactor();
                          if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Đã tắt xác thực 2 lớp.')),
                            );
                          }
                        } else {
                          final pin = pinController.text.trim();
                          final confirm = confirmPinController.text.trim();
                          if (pin.length < 4 || pin.length > 6) {
                            setDialogState(() => localError = 'Mã PIN phải từ 4 đến 6 chữ số');
                            return;
                          }
                          if (pin != confirm) {
                            setDialogState(() => localError = 'Hai mã PIN không trùng khớp');
                            return;
                          }
                          setDialogState(() {
                            isSaving = true;
                            localError = null;
                          });
                          await auth.enableTwoFactor(pin);
                          if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Đã kích hoạt xác thực 2 lớp (2FA) thành công! 🛡️'),
                                backgroundColor: AppColors.success,
                              ),
                            );
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isCurrentlyEnabled ? AppColors.error : AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: isSaving
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(isCurrentlyEnabled ? 'Tắt 2FA' : 'Lưu & Kích Hoạt'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgCanvas,
      appBar: AppBar(
        title: const Text('Hồ Sơ & Kiến Trúc Hệ Thống'),
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
            // 1. User Profile Card
            Consumer<AuthProvider>(
              builder: (context, auth, _) {
                final user = auth.currentUser;
                final email = user?.email ?? 'cuongpro0145@gmail.com';
                final uid = user?.id ?? 'mwqlfjKcb9hnxNe6TpLm6axcpEA3';

                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: AppColors.border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(8),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Stack(
                              children: [
                                CircleAvatar(
                                  radius: 30,
                                  backgroundColor: AppColors.primaryLight,
                                  child: const Icon(Icons.person, size: 36, color: AppColors.primary),
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    width: 14,
                                    height: 14,
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 2),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    email,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  InkWell(
                                    onTap: () {
                                      Clipboard.setData(ClipboardData(text: uid));
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Đã sao chép UID vào bộ nhớ tạm!')),
                                      );
                                    },
                                    borderRadius: BorderRadius.circular(6),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'UID: ${uid.length > 20 ? "${uid.substring(0, 18)}..." : uid}',
                                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontFamily: 'monospace'),
                                        ),
                                        const SizedBox(width: 4),
                                        const Icon(Icons.copy_rounded, size: 12, color: AppColors.textTertiary),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: FirebaseConfig.isFirebaseReady ? Colors.green.withAlpha(25) : Colors.orange.withAlpha(25),
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
                        const SizedBox(height: 16),
                        const Divider(height: 1),
                        const SizedBox(height: 12),

                        // Quick Stats Row
                        Consumer4<NotesProvider, TodosProvider, TeamProvider, ChatProvider>(
                          builder: (context, notes, todos, teams, chat, _) {
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _statItem('Ghi chú', '${notes.notes.length}', Icons.sticky_note_2_outlined, Colors.purple),
                                _statItem('Việc cần làm', '${todos.todos.length}', Icons.checklist_rounded, Colors.teal),
                                _statItem('Nhóm', '${teams.teams.length}', Icons.groups_rounded, Colors.pink),
                                _statItem('Tin nhắn', '${chat.publicMessages.length}', Icons.chat_bubble_outline_rounded, Colors.cyan),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

            // 2. 2FA Security Management Card
            Consumer<AuthProvider>(
              builder: (context, auth, _) {
                final is2FA = auth.currentUser?.isTwoFactorEnabled ?? false;

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: is2FA ? Colors.green.withAlpha(100) : AppColors.border),
                    boxShadow: [
                      BoxShadow(
                        color: is2FA ? Colors.green.withAlpha(15) : Colors.black.withAlpha(5),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: is2FA ? Colors.green.withAlpha(25) : Colors.grey.withAlpha(25),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          is2FA ? Icons.verified_user_rounded : Icons.shield_outlined,
                          color: is2FA ? Colors.green : AppColors.textSecondary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  'Xác Thực 2 Lớp (2FA)',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: is2FA ? Colors.green.withAlpha(20) : Colors.orange.withAlpha(20),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    is2FA ? 'ĐÃ BẬT' : 'CHƯA BẬT',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: is2FA ? Colors.green : Colors.orange,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              is2FA
                                  ? 'Bảo vệ tài khoản bằng mã PIN khi đăng nhập'
                                  : 'Tăng cường bảo mật với mã xác thực 2 bước',
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () => _show2FADialog(context, is2FA),
                        style: TextButton.styleFrom(
                          foregroundColor: is2FA ? AppColors.error : AppColors.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        ),
                        child: Text(is2FA ? 'Quản lý' : 'Bật ngay'),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 22),

            // 3. Database Architecture Section (CLICKABLE TABLES!)
            Row(
              children: [
                const Icon(Icons.storage_rounded, size: 20, color: AppColors.primary),
                const SizedBox(width: 8),
                const Text(
                  'Kiến Trúc Bảng Database (Cloud Firestore)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Padding(
              padding: EdgeInsets.only(left: 28),
              child: Text(
                'Chạm vào bảng bất kỳ để xem chi tiết cấu trúc Schema & Dữ liệu thực tế 🚀',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ),
            const SizedBox(height: 12),

            // Dynamic Interactive Grid of Database Tables
            Consumer4<NotesProvider, TodosProvider, ActivityProvider, ChatProvider>(
              builder: (context, notes, todos, activity, chat, _) {
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 2.1,
                  ),
                  itemCount: DatabaseTablesConfig.allTables.length,
                  itemBuilder: (ctx, index) {
                    final tableMeta = DatabaseTablesConfig.allTables[index];
                    final countDesc = _getTableCount(tableMeta.id, notes, todos, activity, chat);

                    return _interactiveTableCard(
                      context: context,
                      table: tableMeta,
                      countDesc: countDesc,
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 24),

            // 4. Live Activity Log Section
            Row(
              children: [
                const Icon(Icons.history_rounded, size: 20, color: AppColors.textPrimary),
                const SizedBox(width: 8),
                const Text(
                  'Nhật Ký Hoạt Động Hệ Thống (activity_logs)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Consumer<ActivityProvider>(
              builder: (context, activity, _) {
                if (activity.logs.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(22),
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
                        leading: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        title: Text(log.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        subtitle: Text(
                          DateFormatter.formatTimestamp(log.createdAt),
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

  String _getTableCount(
    String tableId,
    NotesProvider notes,
    TodosProvider todos,
    ActivityProvider activity,
    ChatProvider chat,
  ) {
    switch (tableId) {
      case 'users':
        return '${chat.availableUsers.length + 1} tài khoản';
      case 'notes':
        return '${notes.notes.length} ghi chú';
      case 'categories':
        return '4 danh mục';
      case 'todos':
        return '${todos.todos.length} công việc';
      case 'teams':
        return 'Nhóm & phân quyền';
      case 'game_scores':
        return 'Điểm mini-games';
      case 'activity_logs':
        return '${activity.logs.length} nhật ký';
      case 'messages':
        return '${chat.publicMessages.length} tin nhắn';
      default:
        return 'Dữ liệu Firestore';
    }
  }

  Widget _interactiveTableCard({
    required BuildContext context,
    required TableMetadata table,
    required String countDesc,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => FirestoreTableViewerScreen(table: table),
            ),
          );
        },
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(4),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: table.color.withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(table.icon, size: 20, color: table.color),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      table.tableName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      countDesc,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColors.textTertiary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
