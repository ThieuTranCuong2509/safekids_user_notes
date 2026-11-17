import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/config/firebase_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../domain/models/chat_message_entity.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _publicTextController = TextEditingController();
  final _directTextController = TextEditingController();
  final _publicScrollController = ScrollController();
  final _directScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _publicTextController.dispose();
    _directTextController.dispose();
    _publicScrollController.dispose();
    _directScrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom(ScrollController controller) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (controller.hasClients) {
        controller.animateTo(
          controller.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Color _avatarColor(String text) {
    final colors = [
      Colors.blue,
      Colors.purple,
      Colors.teal,
      Colors.orange,
      Colors.indigo,
      Colors.pink,
      Colors.cyan,
      Colors.deepOrange,
    ];
    final hash = text.hashCode.abs();
    return colors[hash % colors.length];
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'U';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgCanvas,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tin Nhắn & Trò Chuyện',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  FirebaseConfig.isFirebaseReady ? 'Firestore Realtime' : 'Chế độ mô phỏng',
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.normal),
                ),
              ],
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          tabs: const [
            Tab(
              icon: Icon(Icons.forum_outlined, size: 20),
              text: 'Kênh Cộng Đồng',
            ),
            Tab(
              icon: Icon(Icons.person_pin_circle_outlined, size: 20),
              text: 'Trực Tiếp (1-1)',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPublicChatTab(),
          _buildDirectChatTab(),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // TAB 1: PUBLIC COMMUNITY CHAT
  // -------------------------------------------------------------
  Widget _buildPublicChatTab() {
    return Consumer2<AuthProvider, ChatProvider>(
      builder: (context, auth, chat, _) {
        final messages = chat.publicMessages;
        final currentUid = auth.currentUser?.id;

        return Column(
          children: [
            // Top Welcome Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppColors.primaryLight.withAlpha(120),
              child: Row(
                children: [
                  const Icon(Icons.campaign_outlined, size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Kênh thảo luận chung cho tất cả thành viên trong hệ thống',
                      style: TextStyle(fontSize: 12, color: AppColors.primaryDark, fontWeight: FontWeight.w500),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.primary.withAlpha(50)),
                    ),
                    child: Text(
                      '${messages.length} tin',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                  ),
                ],
              ),
            ),

            // Messages List
            Expanded(
              child: messages.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.chat_bubble_outline_rounded, size: 56, color: AppColors.textTertiary),
                          const SizedBox(height: 12),
                          const Text('Chưa có tin nhắn nào', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
                          const SizedBox(height: 4),
                          const Text('Hãy gửi tin nhắn đầu tiên để bắt đầu thảo luận! 👋', style: TextStyle(color: AppColors.textTertiary, fontSize: 13)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: _publicScrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      itemCount: messages.length,
                      itemBuilder: (ctx, index) {
                        final msg = messages[index];
                        final isMe = msg.senderId == currentUid;
                        return _buildMessageBubble(msg, isMe);
                      },
                    ),
            ),

            // Composer
            _buildComposer(
              controller: _publicTextController,
              onSend: () {
                final text = _publicTextController.text;
                if (text.trim().isNotEmpty) {
                  chat.sendPublicMessage(text);
                  _publicTextController.clear();
                  _scrollToBottom(_publicScrollController);
                }
              },
            ),
          ],
        );
      },
    );
  }

  // -------------------------------------------------------------
  // TAB 2: DIRECT 1-1 CHAT
  // -------------------------------------------------------------
  Widget _buildDirectChatTab() {
    return Consumer2<AuthProvider, ChatProvider>(
      builder: (context, auth, chat, _) {
        final selectedUser = chat.selectedDirectUser;
        final currentUid = auth.currentUser?.id;

        if (selectedUser == null) {
          // User selector list
          final users = chat.availableUsers;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                child: Row(
                  children: [
                    const Icon(Icons.contacts_rounded, size: 18, color: AppColors.primary),
                    const SizedBox(width: 8),
                    const Text(
                      'Chọn người để nhắn tin trực tiếp (1-1)',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    const Spacer(),
                    Text(
                      '${users.length} người',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: users.isEmpty
                    ? const Center(
                        child: Text('Không tìm thấy người dùng khác trong hệ thống', style: TextStyle(color: AppColors.textSecondary)),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: users.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (ctx, index) {
                          final user = users[index];
                          final name = user.displayName ?? user.email.split('@').first;
                          final color = _avatarColor(user.email);

                          return InkWell(
                            onTap: () {
                              chat.selectDirectUser(user);
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
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
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundColor: color.withAlpha(35),
                                    child: Text(
                                      _getInitials(name),
                                      style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 16),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          name,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          user.email,
                                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryLight,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.chat_bubble_outline, size: 14, color: AppColors.primary),
                                        SizedBox(width: 4),
                                        Text(
                                          'Nhắn tin',
                                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                                        ),
                                      ],
                                    ),
                                  ),
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

        // Direct conversation with selectedUser
        final messages = chat.directMessages;
        final partnerName = selectedUser.displayName ?? selectedUser.email.split('@').first;
        final partnerColor = _avatarColor(selectedUser.email);

        return Column(
          children: [
            // Conversation Header Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                    onPressed: () => chat.selectDirectUser(null),
                  ),
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: partnerColor.withAlpha(30),
                    child: Text(
                      _getInitials(partnerName),
                      style: TextStyle(fontWeight: FontWeight.bold, color: partnerColor, fontSize: 13),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          partnerName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        Text(
                          selectedUser.email,
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withAlpha(20),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.circle, color: Colors.green, size: 8),
                        SizedBox(width: 4),
                        Text('1-1 Private', style: TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Messages
            Expanded(
              child: messages.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.lock_outline_rounded, size: 48, color: AppColors.textTertiary),
                          const SizedBox(height: 12),
                          Text('Bắt đầu cuộc trò chuyện riêng tư với $partnerName', style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                          const SizedBox(height: 4),
                          const Text('Tin nhắn chỉ hiển thị giữa 2 người.', style: TextStyle(color: AppColors.textTertiary, fontSize: 12)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: _directScrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      itemCount: messages.length,
                      itemBuilder: (ctx, index) {
                        final msg = messages[index];
                        final isMe = msg.senderId == currentUid;
                        return _buildMessageBubble(msg, isMe);
                      },
                    ),
            ),

            // Composer
            _buildComposer(
              controller: _directTextController,
              hintText: 'Nhắn tin cho $partnerName...',
              onSend: () {
                final text = _directTextController.text;
                if (text.trim().isNotEmpty) {
                  chat.sendDirectMessage(text);
                  _directTextController.clear();
                  _scrollToBottom(_directScrollController);
                }
              },
            ),
          ],
        );
      },
    );
  }

  // -------------------------------------------------------------
  // MESSAGE BUBBLE WIDGET
  // -------------------------------------------------------------
  Widget _buildMessageBubble(ChatMessageEntity msg, bool isMe) {
    final senderInitials = _getInitials(msg.senderName);
    final color = _avatarColor(msg.senderEmail);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: color.withAlpha(35),
              child: Text(
                senderInitials,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isMe)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 4),
                    child: Text(
                      msg.senderName,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isMe ? AppColors.primary : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isMe ? 18 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 18),
                    ),
                    border: isMe ? null : Border.all(color: AppColors.border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(isMe ? 25 : 8),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    msg.text,
                    style: TextStyle(
                      fontSize: 14,
                      color: isMe ? Colors.white : AppColors.textPrimary,
                      height: 1.35,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
                  child: Text(
                    DateFormatter.formatTimestamp(msg.createdAt),
                    style: const TextStyle(fontSize: 10, color: AppColors.textTertiary),
                  ),
                ),
              ],
            ),
          ),
          if (isMe) const SizedBox(width: 4),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // COMPOSER WIDGET
  // -------------------------------------------------------------
  Widget _buildComposer({
    required TextEditingController controller,
    required VoidCallback onSend,
    String hintText = 'Nhập tin nhắn thảo luận...',
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.bgCanvas,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.border),
                ),
                child: TextField(
                  controller: controller,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => onSend(),
                  minLines: 1,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: hintText,
                    hintStyle: const TextStyle(fontSize: 13, color: AppColors.textTertiary),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2563EB), Color(0xFF4F46E5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withAlpha(60),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                onPressed: onSend,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
