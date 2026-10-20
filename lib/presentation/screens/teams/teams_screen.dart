import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/models/team_entity.dart';
import '../../providers/auth_provider.dart';
import '../../providers/team_provider.dart';

class TeamsScreen extends StatefulWidget {
  const TeamsScreen({super.key});

  @override
  State<TeamsScreen> createState() => _TeamsScreenState();
}

class _TeamsScreenState extends State<TeamsScreen> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _showCreateTeamDialog() {
    _nameController.clear();
    _descController.clear();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Tạo Nhóm Làm Việc Mới'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Tên nhóm (Team Name)',
                hintText: 'Ví dụ: Nhóm Đồ Án Tốt Nghiệp',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descController,
              decoration: const InputDecoration(
                labelText: 'Mô tả nhóm',
                hintText: 'Mục tiêu, nhiệm vụ chung...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () {
              final name = _nameController.text.trim();
              if (name.isNotEmpty) {
                context.read<TeamProvider>().createTeam(
                  name: name,
                  description: _descController.text.trim(),
                );
                Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Tạo Nhóm'),
          ),
        ],
      ),
    );
  }

  void _showTeamDetails(TeamEntity team) {
    final auth = context.read<AuthProvider>();
    final currentUid = auth.currentUser?.id ?? '';
    final isOwner = team.isOwner(currentUid);
    final userRole = team.getRole(currentUid);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        team.name,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                    _roleBadge(userRole),
                  ],
                ),
                if (team.description.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(team.description, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                ],
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Thành viên nhóm', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    if (isOwner)
                      TextButton.icon(
                        icon: const Icon(Icons.person_add_alt_1, size: 16),
                        label: const Text('Thêm TV'),
                        onPressed: () => _showAddMemberDialog(team, sheetCtx),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                ...team.memberIds.map((mId) {
                  final role = team.getRole(mId);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.bgCanvas,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.account_circle, size: 28, color: AppColors.primary),
                            const SizedBox(width: 10),
                            Text(
                              mId == currentUid ? '$mId (Tôi)' : mId,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            _roleBadge(role),
                            if (isOwner && mId != team.ownerId)
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline, size: 18, color: AppColors.error),
                                onPressed: () {
                                  context.read<TeamProvider>().removeMember(mId);
                                  Navigator.pop(sheetCtx);
                                },
                              ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showAddMemberDialog(TeamEntity team, BuildContext parentSheetCtx) {
    final emailCtrl = TextEditingController();
    String selectedRole = 'editor';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Thêm Thành Viên & Phân Quyền'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: emailCtrl,
                decoration: const InputDecoration(
                  labelText: 'Email hoặc ID thành viên',
                  hintText: 'member@gmail.com',
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: selectedRole,
                decoration: const InputDecoration(labelText: 'Vai trò (Role)'),
                items: const [
                  DropdownMenuItem(value: 'editor', child: Text('Biên tập viên (Editor - Thêm/Sửa ghi chú)')),
                  DropdownMenuItem(value: 'viewer', child: Text('Người xem (Viewer - Chỉ đọc)')),
                ],
                onChanged: (val) {
                  if (val != null) setDlgState(() => selectedRole = val);
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
            ElevatedButton(
              onPressed: () {
                final id = emailCtrl.text.trim();
                if (id.isNotEmpty) {
                  context.read<TeamProvider>().addMember(id, selectedRole);
                  Navigator.pop(ctx);
                  Navigator.pop(parentSheetCtx);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Thêm'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _roleBadge(String role) {
    Color color;
    String label;
    switch (role) {
      case 'owner':
        color = Colors.purple;
        label = 'Trưởng nhóm';
        break;
      case 'editor':
        color = Colors.teal;
        label = 'Biên tập (Editor)';
        break;
      default:
        color = Colors.blueGrey;
        label = 'Chỉ xem (Viewer)';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgCanvas,
      appBar: AppBar(
        title: const Text('Nhóm Làm Việc & Phân Quyền (RBAC)'),
        actions: [
          IconButton(
            tooltip: 'Tạo nhóm mới',
            icon: const Icon(Icons.group_add_rounded),
            onPressed: _showCreateTeamDialog,
          ),
        ],
      ),
      body: SafeArea(
        child: Consumer2<TeamProvider, AuthProvider>(
          builder: (context, teamProvider, auth, _) {
            final currentUid = auth.currentUser?.id ?? '';
            final teams = teamProvider.teams;

            if (teams.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.groups_outlined, size: 64, color: AppColors.textTertiary),
                    const SizedBox(height: 12),
                    const Text('Bạn chưa tham gia nhóm làm việc nào', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 6),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Tạo Nhóm Đầu Tiên'),
                      onPressed: _showCreateTeamDialog,
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: teams.length,
              itemBuilder: (context, index) {
                final team = teams[index];
                final role = team.getRole(currentUid);
                final isSelected = teamProvider.activeTeam?.id == team.id;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.border,
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(10),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primaryLight,
                      child: const Icon(Icons.groups_rounded, color: AppColors.primary),
                    ),
                    title: Text(
                      team.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (team.description.isNotEmpty)
                          Text(
                            team.description,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        const SizedBox(height: 4),
                        Text('${team.memberIds.length} thành viên', style: const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _roleBadge(role),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.info_outline, color: AppColors.primary),
                          onPressed: () => _showTeamDetails(team),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
