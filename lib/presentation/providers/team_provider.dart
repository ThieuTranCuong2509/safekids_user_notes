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
    if (_activeTeam == null || _userId == null) return true; // Personal mode has full access
    return _activeTeam!.canEdit(_userId!);
  }

  bool get isOwnerActiveTeam {
    if (_activeTeam == null || _userId == null) return true;
    return _activeTeam!.isOwner(_userId!);
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

    if (FirebaseConfig.isFirebaseReady) {
      _isLoading = true;
      notifyListeners();
      _teamsSub = firestoreService.watchUserTeams(userId).listen(
        (list) {
          _teams = list;
          _isLoading = false;
          notifyListeners();
        },
        onError: (_) {
          _isLoading = false;
          _teams = List.from(_localTeams);
          notifyListeners();
        },
      );
    } else {
      if (_localTeams.isEmpty) {
        final now = DateTime.now().millisecondsSinceEpoch;
        _localTeams.add(
          TeamEntity(
            id: 'mock_team_grad',
            name: 'Nhóm Đồ Án Tốt Nghiệp',
            description: 'Nhóm làm việc và chia sẻ tài liệu báo cáo tốt nghiệp',
            ownerId: userId,
            memberIds: [userId, 'member_dung', 'member_nam'],
            memberRoles: {
              userId: 'owner',
              'member_dung': 'editor',
              'member_nam': 'viewer',
            },
            createdAt: now - 86400000,
            updatedAt: now - 86400000,
          ),
        );
      }
      _teams = List.from(_localTeams);
      notifyListeners();
    }
  }

  void selectTeam(TeamEntity? team) {
    _activeTeam = team;
    notifyListeners();
  }

  Future<TeamEntity?> createTeam({required String name, String description = ''}) async {
    if (_userId == null || name.trim().isEmpty) return null;

    if (FirebaseConfig.isFirebaseReady) {
      final team = await firestoreService.createTeam(
        ownerId: _userId!,
        name: name.trim(),
        description: description.trim(),
      );
      selectTeam(team);
      return team;
    } else {
      final now = DateTime.now().millisecondsSinceEpoch;
      final team = TeamEntity(
        id: 'mock_team_$now',
        name: name.trim(),
        description: description.trim(),
        ownerId: _userId!,
        memberIds: [_userId!],
        memberRoles: {_userId!: 'owner'},
        createdAt: now,
        updatedAt: now,
      );
      _localTeams.add(team);
      _teams = List.from(_localTeams);
      selectTeam(team);
      notifyListeners();
      return team;
    }
  }

  Future<void> addMember(String emailOrId, String role) async {
    if (_activeTeam == null || emailOrId.trim().isEmpty) return;
    final cleanId = emailOrId.trim();

    if (FirebaseConfig.isFirebaseReady) {
      await firestoreService.addMemberToTeam(
        teamId: _activeTeam!.id,
        memberId: cleanId,
        role: role,
      );
    } else {
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
    }
  }

  Future<void> updateMemberRole(String memberId, String role) async {
    if (_activeTeam == null) return;

    if (FirebaseConfig.isFirebaseReady) {
      await firestoreService.updateMemberRole(
        teamId: _activeTeam!.id,
        memberId: memberId,
        role: role,
      );
    } else {
      final currentRoles = Map<String, String>.from(_activeTeam!.memberRoles);
      currentRoles[memberId] = role;
      _activeTeam = _activeTeam!.copyWith(memberRoles: currentRoles);
      final idx = _localTeams.indexWhere((t) => t.id == _activeTeam!.id);
      if (idx != -1) _localTeams[idx] = _activeTeam!;
      _teams = List.from(_localTeams);
      notifyListeners();
    }
  }

  Future<void> removeMember(String memberId) async {
    if (_activeTeam == null) return;

    if (FirebaseConfig.isFirebaseReady) {
      await firestoreService.removeMemberFromTeam(
        teamId: _activeTeam!.id,
        memberId: memberId,
      );
    } else {
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
    }
  }

  @override
  void dispose() {
    _teamsSub?.cancel();
    super.dispose();
  }
}
