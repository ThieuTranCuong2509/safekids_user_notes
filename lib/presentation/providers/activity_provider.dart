import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../domain/models/activity_log_entity.dart';
import '../../data/services/firestore_service.dart';
import '../../core/config/firebase_config.dart';

class ActivityProvider extends ChangeNotifier {
  final FirestoreService firestoreService;
  StreamSubscription<List<ActivityLogEntity>>? _sub;

  String? _userId;
  List<ActivityLogEntity> _logs = [];
  bool _isLoading = false;

  final List<ActivityLogEntity> _localLogs = [];

  ActivityProvider({required this.firestoreService});

  List<ActivityLogEntity> get logs => _logs;
  bool get isLoading => _isLoading;

  void syncUser(String? userId) {
    if (_userId == userId) return;
    _userId = userId;
    _sub?.cancel();
    _sub = null;

    if (userId == null) {
      _logs = [];
      notifyListeners();
      return;
    }

    if (FirebaseConfig.isFirebaseReady) {
      _isLoading = true;
      notifyListeners();
      _sub = firestoreService.watchActivityLogs(userId).listen(
        (list) {
          _logs = list;
          _isLoading = false;
          notifyListeners();
        },
        onError: (_) {
          _isLoading = false;
          _logs = List.from(_localLogs);
          notifyListeners();
        },
      );
    } else {
      if (_localLogs.isEmpty) {
        final now = DateTime.now().millisecondsSinceEpoch;
        _localLogs.addAll([
          ActivityLogEntity(
            id: 'mock_l1',
            userId: userId,
            action: 'login',
            title: 'Đăng nhập vào hệ thống',
            details: 'Phiên hoạt động mới bắt đầu',
            createdAt: now - 3600000,
          ),
          ActivityLogEntity(
            id: 'mock_l2',
            userId: userId,
            action: 'create_note',
            title: 'Tạo ghi chú mới',
            details: 'Báo cáo đồ án tốt nghiệp',
            createdAt: now - 1800000,
          ),
        ]);
      }
      _logs = List.from(_localLogs);
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
