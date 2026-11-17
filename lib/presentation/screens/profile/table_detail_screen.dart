import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/config/firebase_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/services/firestore_service.dart';
import '../../providers/activity_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/notes_provider.dart';
import '../../providers/team_provider.dart';
import '../../providers/todos_provider.dart';

class TableSchemaField {
  final String fieldName;
  final String fieldType;
  final String description;
  final bool isRequired;

  const TableSchemaField({
    required this.fieldName,
    required this.fieldType,
    required this.description,
    this.isRequired = true,
  });
}

class TableMetadata {
  final String id;
  final String tableName;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String securityRule;
  final List<TableSchemaField> schema;

  const TableMetadata({
    required this.id,
    required this.tableName,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.securityRule,
    required this.schema,
  });
}

class FirestoreTableViewerScreen extends StatefulWidget {
  final TableMetadata table;

  const FirestoreTableViewerScreen({super.key, required this.table});

  @override
  State<FirestoreTableViewerScreen> createState() => _FirestoreTableViewerScreenState();
}

class _FirestoreTableViewerScreenState extends State<FirestoreTableViewerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _records = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadRecords();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRecords() async {
    setState(() => _isLoading = true);

    List<Map<String, dynamic>> fetched = [];

    // Attempt to load from Firestore service first
    if (FirebaseConfig.isFirebaseReady) {
      try {
        final fs = FirestoreService();
        final cloudDocs = await fs.getCollectionRecords(widget.table.id);
        if (cloudDocs.isNotEmpty) {
          fetched = cloudDocs;
        }
      } catch (e) {
        debugPrint('[TableViewer] load error: $e');
      }
    }

    // If empty or offline, fallback to rich Provider / local data
    if (fetched.isEmpty && mounted) {
      fetched = _getFallbackProviderData();
    }

    if (mounted) {
      setState(() {
        _records = fetched;
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> _getFallbackProviderData() {
    switch (widget.table.id) {
      case 'users':
        final chatUsers = context.read<ChatProvider>().availableUsers;
        return chatUsers.map((u) => u.toMap()).toList();

      case 'notes':
        final notes = context.read<NotesProvider>().notes;
        return notes.map((n) => n.toMap()).toList();

      case 'todos':
        final todos = context.read<TodosProvider>().todos;
        return todos.map((t) => t.toMap()).toList();

      case 'teams':
        final teams = context.read<TeamProvider>().teams;
        return teams.map((t) => t.toMap()).toList();

      case 'activity_logs':
        final logs = context.read<ActivityProvider>().logs;
        return logs.map((l) => l.toMap()).toList();

      case 'messages':
        final msgs = context.read<ChatProvider>().publicMessages;
        return msgs.map((m) => m.toMap()).toList();

      case 'categories':
        return [
          {
            '_docId': 'cat_general',
            'id': 'general',
            'name': 'Chung (Default)',
            'colorHex': '#2196F3',
            'iconName': 'folder',
            'createdAt': DateTime.now().millisecondsSinceEpoch - 86400000 * 5,
          },
          {
            '_docId': 'cat_study',
            'id': 'study',
            'name': 'Học tập & Đồ án',
            'colorHex': '#4CAF50',
            'iconName': 'school',
            'createdAt': DateTime.now().millisecondsSinceEpoch - 86400000 * 4,
          },
          {
            '_docId': 'cat_work',
            'id': 'work',
            'name': 'Công việc & Dự án',
            'colorHex': '#FF9800',
            'iconName': 'work',
            'createdAt': DateTime.now().millisecondsSinceEpoch - 86400000 * 3,
          },
          {
            '_docId': 'cat_idea',
            'id': 'idea',
            'name': 'Ý tưởng sáng tạo',
            'colorHex': '#9C27B0',
            'iconName': 'lightbulb',
            'createdAt': DateTime.now().millisecondsSinceEpoch - 86400000 * 2,
          },
        ];

      case 'game_scores':
        return [
          {
            '_docId': 'score_1',
            'userId': 'user_cuongtran',
            'userName': 'Cường Trần (Leader)',
            'gameType': 'flappy_bird',
            'score': 128,
            'difficulty': 'normal',
            'timeSpentSeconds': 95,
            'createdAt': DateTime.now().millisecondsSinceEpoch - 3600000,
          },
          {
            '_docId': 'score_2',
            'userId': 'user_dung',
            'userName': 'Nguyễn Tiến Dũng',
            'gameType': 'memory_match',
            'score': 95,
            'difficulty': 'hard',
            'timeSpentSeconds': 42,
            'createdAt': DateTime.now().millisecondsSinceEpoch - 7200000,
          },
          {
            '_docId': 'score_3',
            'userId': 'user_nam',
            'userName': 'Trần Hoài Nam',
            'gameType': 'math_blitz',
            'score': 88,
            'difficulty': 'normal',
            'timeSpentSeconds': 60,
            'createdAt': DateTime.now().millisecondsSinceEpoch - 14400000,
          },
        ];

      default:
        return [];
    }
  }

  List<Map<String, dynamic>> get _filteredRecords {
    if (_searchQuery.trim().isEmpty) return _records;
    final q = _searchQuery.toLowerCase();
    return _records.where((r) {
      return r.values.any((val) => val.toString().toLowerCase().contains(q));
    }).toList();
  }

  void _inspectDocument(Map<String, dynamic> doc) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.75,
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.data_object_rounded, color: widget.table.color, size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Chi Tiết Bản Ghi: ${doc['_docId'] ?? doc['id'] ?? "Document"}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  tooltip: 'Sao chép JSON',
                  icon: const Icon(Icons.copy_rounded, size: 20),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: jsonEncode(doc)));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đã sao chép JSON vào bộ nhớ tạm!')),
                    );
                  },
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child: ListView(
                children: doc.entries.map((entry) {
                  final key = entry.key;
                  final value = entry.value;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.bgCanvas,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              key,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: widget.table.color,
                                fontFamily: 'monospace',
                                fontSize: 13,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.grey.withAlpha(20),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                value.runtimeType.toString(),
                                style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          value.toString(),
                          style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgCanvas,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.table.tableName, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            Text(
              widget.table.title,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Làm mới dữ liệu',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadRecords,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: widget.table.color,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: widget.table.color,
          tabs: [
            Tab(
              icon: const Icon(Icons.table_chart_outlined, size: 20),
              text: 'Dữ Liệu (${_records.length})',
            ),
            const Tab(
              icon: Icon(Icons.schema_outlined, size: 20),
              text: 'Cấu Trúc Schema',
            ),
            const Tab(
              icon: Icon(Icons.security_rounded, size: 20),
              text: 'Bảo Mật (Rules)',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Live Records List
          _buildRecordsTab(),

          // Tab 2: Schema definition
          _buildSchemaTab(),

          // Tab 3: Security rules
          _buildSecurityRulesTab(),
        ],
      ),
    );
  }

  Widget _buildRecordsTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final filtered = _filteredRecords;

    return Column(
      children: [
        // Summary & Search Bar
        Container(
          padding: const EdgeInsets.all(14),
          color: Colors.white,
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: widget.table.color.withAlpha(25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(widget.table.icon, size: 16, color: widget.table.color),
                        const SizedBox(width: 6),
                        Text(
                          '${_records.length} Documents',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: widget.table.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    FirebaseConfig.isFirebaseReady ? 'Firestore Live Sync' : 'Dev Memory Mode',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: FirebaseConfig.isFirebaseReady ? Colors.green : Colors.orange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm bản ghi trong ${widget.table.tableName}...',
                  prefixIcon: const Icon(Icons.search, size: 18),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  filled: true,
                  fillColor: AppColors.bgCanvas,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                ),
              ),
            ],
          ),
        ),

        // List
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inbox_outlined, size: 48, color: AppColors.textTertiary),
                      const SizedBox(height: 12),
                      Text(
                        _searchQuery.isNotEmpty ? 'Không tìm thấy kết quả phù hợp' : 'Bảng này chưa có tài liệu nào',
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(14),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (ctx, index) {
                    final item = filtered[index];
                    final docId = item['_docId'] ?? item['id'] ?? 'doc_$index';
                    final title = item['title'] ?? item['name'] ?? item['email'] ?? item['userName'] ?? item['text'] ?? docId;
                    final time = item['createdAt'] ?? item['updatedAt'];

                    return InkWell(
                      onTap: () => _inspectDocument(item),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(5),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: widget.table.color.withAlpha(20),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: widget.table.color,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title.toString(),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'ID: $docId',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                  if (time != null && time is num) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      DateFormatter.formatTimestamp(time.toInt()),
                                      style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textTertiary),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSchemaTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(widget.table.icon, color: widget.table.color, size: 24),
                  const SizedBox(width: 10),
                  Text(
                    widget.table.tableName,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                widget.table.subtitle,
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Đặc Tả Trường Dữ Liệu (Field Definitions)',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 10),
        ...widget.table.schema.map((f) {
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            f.fieldName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                              fontSize: 14,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              f.fieldType,
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        f.description,
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.3),
                      ),
                    ],
                  ),
                ),
                if (f.isRequired)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red.withAlpha(20),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Bắt buộc',
                      style: TextStyle(fontSize: 9, color: Colors.red, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildSecurityRulesTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.shield_outlined, color: Colors.green, size: 24),
                  SizedBox(width: 10),
                  Text(
                    'Firestore Security Rules',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                'Quy tắc bảo mật phân quyền ở cấp độ backend Cloud Firestore, đảm bảo người dùng chỉ được đọc/ghi dữ liệu được cấp quyền.',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SelectableText(
                  widget.table.securityRule,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13,
                    color: Color(0xFF38BDF8),
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
