import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../core/config/firebase_config.dart';
import '../../data/services/firestore_service.dart';
import '../../domain/models/chat_message_entity.dart';
import '../../domain/models/user_entity.dart';

class ChatProvider extends ChangeNotifier {
  final FirestoreService firestoreService;

  StreamSubscription<List<ChatMessageEntity>>? _publicSub;
  StreamSubscription<List<ChatMessageEntity>>? _directSub;
  StreamSubscription<List<UserEntity>>? _usersSub;

  String? _currentUserId;
  String? _currentUserEmail;
  String? _currentUserName;

  List<ChatMessageEntity> _publicMessages = [];
  List<ChatMessageEntity> _directMessages = [];
  List<UserEntity> _availableUsers = [];
  UserEntity? _selectedDirectUser;
  final bool _isLoading = false;

  final List<ChatMessageEntity> _localPublicMessages = [];
  final List<ChatMessageEntity> _localDirectMessages = [];

  ChatProvider({required this.firestoreService});

  List<ChatMessageEntity> get publicMessages => _publicMessages;
  List<ChatMessageEntity> get directMessages => _directMessages;
  List<UserEntity> get availableUsers => _availableUsers;
  UserEntity? get selectedDirectUser => _selectedDirectUser;
  bool get isLoading => _isLoading;
  String? get currentUserId => _currentUserId;

  static List<ChatMessageEntity> _initialPublicSeed() {
    final now = DateTime.now().millisecondsSinceEpoch;
    return [
      ChatMessageEntity(
        id: 'msg_seed_1',
        senderId: 'system',
        senderEmail: 'hethong@safekids.vn',
        senderName: 'SafeKids Bot',
        receiverId: 'public',
        text: 'Chào mừng các bạn đến với Kênh Thảo Luận Chung! 👋 Hệ thống tin nhắn thời gian thực hỗ trợ trao đổi đồ án và ghi chú.',
        createdAt: now - 3600000 * 2,
      ),
      ChatMessageEntity(
        id: 'msg_seed_2',
        senderId: 'demo_user_1',
        senderEmail: 'dung@gmail.com',
        senderName: 'Nguyễn Tiến Dũng',
        receiverId: 'public',
        text: 'Mình vừa cập nhật tài liệu báo cáo tốt nghiệp lên nhóm, mọi người vào xem nhé!',
        createdAt: now - 3600000,
      ),
      ChatMessageEntity(
        id: 'msg_seed_3',
        senderId: 'demo_user_2',
        senderEmail: 'nam@gmail.com',
        senderName: 'Trần Hoài Nam',
        receiverId: 'public',
        text: 'Giao diện mới đẹp và trực quan hơn nhiều rồi đó Cường 👍',
        createdAt: now - 1800000,
      ),
    ];
  }

  static List<UserEntity> _initialDemoUsers() {
    final now = DateTime.now().millisecondsSinceEpoch;
    return [
      UserEntity(
        id: 'demo_user_1',
        email: 'dung@gmail.com',
        displayName: 'Nguyễn Tiến Dũng',
        createdAt: now - 86400000 * 3,
        totalNotes: 4,
      ),
      UserEntity(
        id: 'demo_user_2',
        email: 'nam@gmail.com',
        displayName: 'Trần Hoài Nam',
        createdAt: now - 86400000 * 2,
        totalNotes: 2,
      ),
      UserEntity(
        id: 'demo_user_3',
        email: 'giangvien@hust.edu.vn',
        displayName: 'TS. Giảng Viên Hướng Dẫn',
        createdAt: now - 86400000 * 10,
        totalNotes: 8,
      ),
    ];
  }

  void syncUser(UserEntity? user) {
    final userId = user?.id;
    if (_currentUserId == userId &&
        _currentUserEmail == user?.email &&
        _currentUserName == (user?.displayName ?? user?.email.split('@').first)) {
      return;
    }

    _currentUserId = userId;
    _currentUserEmail = user?.email;
    _currentUserName = user?.displayName ?? user?.email.split('@').first ?? 'User';

    _publicSub?.cancel();
    _publicSub = null;
    _directSub?.cancel();
    _directSub = null;
    _usersSub?.cancel();
    _usersSub = null;

    if (userId == null) {
      _publicMessages = [];
      _directMessages = [];
      _availableUsers = [];
      _selectedDirectUser = null;
      notifyListeners();
      return;
    }

    if (_localPublicMessages.isEmpty) {
      _localPublicMessages.addAll(_initialPublicSeed());
    }
    _publicMessages = List.from(_localPublicMessages);
    _availableUsers = _initialDemoUsers();
    notifyListeners();

    if (FirebaseConfig.isFirebaseReady) {
      // 1. Listen to public messages
      _publicSub = firestoreService.watchPublicMessages().listen(
        (list) {
          if (list.isNotEmpty) {
            _publicMessages = list;
          } else {
            _publicMessages = List.from(_localPublicMessages);
          }
          notifyListeners();
        },
        onError: (err) {
          debugPrint('[ChatProvider] public messages error: $err');
          _publicMessages = List.from(_localPublicMessages);
          notifyListeners();
        },
      );

      // 2. Listen to available users in system
      _usersSub = firestoreService.watchUsers().listen(
        (list) {
          // Exclude current user from contact list
          final otherUsers = list.where((u) => u.id != userId).toList();
          if (otherUsers.isNotEmpty) {
            _availableUsers = otherUsers;
          } else {
            _availableUsers = _initialDemoUsers();
          }
          notifyListeners();
        },
        onError: (_) {
          _availableUsers = _initialDemoUsers();
          notifyListeners();
        },
      );
    }
  }

  void selectDirectUser(UserEntity? otherUser) {
    if (_selectedDirectUser?.id == otherUser?.id) return;
    _selectedDirectUser = otherUser;
    _directSub?.cancel();
    _directSub = null;

    if (otherUser == null || _currentUserId == null) {
      _directMessages = [];
      notifyListeners();
      return;
    }

    // Filter local direct messages
    _directMessages = _localDirectMessages
        .where((m) =>
            (m.senderId == _currentUserId && m.receiverId == otherUser.id) ||
            (m.senderId == otherUser.id && m.receiverId == _currentUserId))
        .toList();
    notifyListeners();

    if (FirebaseConfig.isFirebaseReady) {
      _directSub = firestoreService
          .watchDirectMessages(_currentUserId!, otherUser.id)
          .listen(
        (list) {
          _directMessages = list;
          notifyListeners();
        },
        onError: (e) {
          debugPrint('[ChatProvider] direct messages error: $e');
        },
      );
    }
  }

  Future<void> sendPublicMessage(String text) async {
    final clean = text.trim();
    if (clean.isEmpty || _currentUserId == null) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    final msg = ChatMessageEntity(
      id: 'local_msg_$now',
      senderId: _currentUserId!,
      senderEmail: _currentUserEmail ?? 'user@cuongtran.notes',
      senderName: _currentUserName ?? 'Tôi',
      receiverId: 'public',
      text: clean,
      createdAt: now,
    );

    _localPublicMessages.add(msg);
    _publicMessages = List.from(_localPublicMessages);
    notifyListeners();

    if (FirebaseConfig.isFirebaseReady) {
      await firestoreService.sendChatMessage(
        senderId: _currentUserId!,
        senderEmail: _currentUserEmail ?? '',
        senderName: _currentUserName ?? 'User',
        receiverId: 'public',
        text: clean,
      );
    }
  }

  Future<void> sendDirectMessage(String text) async {
    final clean = text.trim();
    if (clean.isEmpty || _currentUserId == null || _selectedDirectUser == null) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    final msg = ChatMessageEntity(
      id: 'local_dm_$now',
      senderId: _currentUserId!,
      senderEmail: _currentUserEmail ?? 'user@cuongtran.notes',
      senderName: _currentUserName ?? 'Tôi',
      receiverId: _selectedDirectUser!.id,
      receiverName: _selectedDirectUser!.displayName ?? _selectedDirectUser!.email,
      text: clean,
      createdAt: now,
    );

    _localDirectMessages.add(msg);
    _directMessages = _localDirectMessages
        .where((m) =>
            (m.senderId == _currentUserId && m.receiverId == _selectedDirectUser!.id) ||
            (m.senderId == _selectedDirectUser!.id && m.receiverId == _currentUserId))
        .toList();
    notifyListeners();

    if (FirebaseConfig.isFirebaseReady) {
      await firestoreService.sendChatMessage(
        senderId: _currentUserId!,
        senderEmail: _currentUserEmail ?? '',
        senderName: _currentUserName ?? 'User',
        receiverId: _selectedDirectUser!.id,
        receiverName: _selectedDirectUser!.displayName ?? _selectedDirectUser!.email,
        text: clean,
      );
    }
  }

  @override
  void dispose() {
    _publicSub?.cancel();
    _directSub?.cancel();
    _usersSub?.cancel();
    super.dispose();
  }
}
