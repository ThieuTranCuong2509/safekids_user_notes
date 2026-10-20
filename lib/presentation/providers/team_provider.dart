import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../domain/models/team_entity.dart';
import '../../data/services/firestore_service.dart';
import '../../core/config/firebase_config.dart';

class TeamProvider extends ChangeNotifier {
  final FirestoreService firestoreService;
  StreamSubscription<List<TeamEntity>>? _teamsSub;

  String? _userId;
  List<TeamEntity> _teams = [];
  TeamEntity? _activeTeam;
  bool _isLoading = false;

  final List<TeamEntity> _localTeams = [];

  TeamProvider({required this.firestoreService});

  List<TeamEntity> get teams => _teams;
  TeamEntity? get activeTeam => _activeTeam;
  bool get isLoading => _isLoading;

  bool get canEditActiveTeam {
    if (_activeTeam == null || _userId == null) return true;
    return _activeTeam!.canEdit(_userId!);
  }

  bool get isOwnerActiveTeam {
    if (_activeTeam == null || _userId == null) return true;
    return _activeTeam!.isOwner(_userId!);
  }

  static TeamEntity _seedTeam(String userId) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return TeamEntity(
      id: 'mock_team_grad',
      name: 'Nhóm Đồ Án Tốt Nghiệp',
      description: 'Nhóm làm việc và chia sẻ tài liệu báo cáo tốt nghiệp',
      ownerId: userId,
      memberIds: [userId, 'dung@gmail.com', 'nam@gmail.com'],
      memberRoles: {
        userId: 'owner',
        'dung@gmail.com': 'editor',
        'nam@gmail.com': 'viewer',
      },
      createdAt: now - 86400000,
      updatedAt: now - 86400000,
    );
  }

  void syncUser(String? userId) {
    if (_userId == userId) return;
    _userId = userId;
    _teamsSub?.cancel();
    _teamsSub = null;
    _activeTeam = null;

    if (userId == null) {
      _teams = [];
      notifyListeners();
      return;
    }

    if (_localTeams.isEmpty) {
      _localTeams.add(_seedTeam(userId));
    }
    _teams = List.from(_localTeams);
    _isLoading = false;
    notifyListeners();

    if (FirebaseConfig.isFirebaseReady) {
      _teamsSub = firestoreService.watchUserTeams(userId).listen(
        (list) {
          if (list.isNotEmpty) {
            _teams = list;
          }
          _isLoading = false;
          notifyListeners();
        },
        onError: (_) {
          _isLoading = false;
          if (_teams.isEmpty) {
            _teams = List.from(_localTeams);
          }
          notifyListeners();
        },
      );
    }
  }

  void selectTeam(TeamEntity? team) {
    _activeTeam = team;
    notifyListeners();
  }

  Future<TeamEntity?> createTeam({required String name, String description = ''}) async {
    if (_userId == null || name.trim().isEmpty) return null;

    final now = DateTime.now().millisecondsSinceEpoch;
    final team = TeamEntity(
      id: 'team_$now',
      name: name.trim(),
      description: description.trim(),
      ownerId: _userId!,
      memberIds: [_userId!],
      memberRoles: {_userId!: 'owner'},
      createdAt: now,
      updatedAt: now,
    );

    _localTeams.insert(0, team);
    _teams = List.from(_localTeams);
    selectTeam(team);
    notifyListeners();

    if (FirebaseConfig.isFirebaseReady) {
      try {
        await firestoreService.createTeam(
          ownerId: _userId!,
          name: name.trim(),
          description: description.trim(),
        );
      } catch (_) {}
    }
    return team;
  }

  Future<void> addMember(String emailOrId, String role) async {
    if (_activeTeam == null || emailOrId.trim().isEmpty) return;
    final cleanId = emailOrId.trim();

    final currentRoles = Map<String, String>.from(_activeTeam!.memberRoles);
    currentRoles[cleanId] = role;
    final currentMembers = List<String>.from(_activeTeam!.memberIds);
    if (!currentMembers.contains(cleanId)) currentMembers.add(cleanId);

    _activeTeam = _activeTeam!.copyWith(
      memberIds: currentMembers,
      memberRoles: currentRoles,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );

    final idx = _localTeams.indexWhere((t) => t.id == _activeTeam!.id);
    if (idx != -1) _localTeams[idx] = _activeTeam!;
    _teams = List.from(_localTeams);
    notifyListeners();

    if (FirebaseConfig.isFirebaseReady) {
      try {
        await firestoreService.addMemberToTeam(
          teamId: _activeTeam!.id,
          memberId: cleanId,
          role: role,
        );
      } catch (_) {}
    }
  }

  Future<void> updateMemberRole(String memberId, String role) async {
    if (_activeTeam == null) return;

    final currentRoles = Map<String, String>.from(_activeTeam!.memberRoles);
    currentRoles[memberId] = role;
    _activeTeam = _activeTeam!.copyWith(memberRoles: currentRoles);

    final idx = _localTeams.indexWhere((t) => t.id == _activeTeam!.id);
    if (idx != -1) _localTeams[idx] = _activeTeam!;
    _teams = List.from(_localTeams);
    notifyListeners();

    if (FirebaseConfig.isFirebaseReady) {
      try {
        await firestoreService.updateMemberRole(
          teamId: _activeTeam!.id,
          memberId: memberId,
          role: role,
        );
      } catch (_) {}
    }
  }

  Future<void> removeMember(String memberId) async {
    if (_activeTeam == null) return;

    final currentRoles = Map<String, String>.from(_activeTeam!.memberRoles)..remove(memberId);
    final currentMembers = List<String>.from(_activeTeam!.memberIds)..remove(memberId);
    _activeTeam = _activeTeam!.copyWith(
      memberIds: currentMembers,
      memberRoles: currentRoles,
    );

    final idx = _localTeams.indexWhere((t) => t.id == _activeTeam!.id);
    if (idx != -1) _localTeams[idx] = _activeTeam!;
    _teams = List.from(_localTeams);
    notifyListeners();

    if (FirebaseConfig.isFirebaseReady) {
      try {
        await firestoreService.removeMemberFromTeam(
          teamId: _activeTeam!.id,
          memberId: memberId,
        );
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _teamsSub?.cancel();
    super.dispose();
  }
}
