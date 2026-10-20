import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../domain/models/game_score_entity.dart';
import '../../data/services/firestore_service.dart';
import '../../core/config/firebase_config.dart';

class GamesProvider extends ChangeNotifier {
  final FirestoreService firestoreService;
  StreamSubscription<List<GameScoreEntity>>? _scoreSub;

  String? _userId;
  String _userName = 'Player';
  List<GameScoreEntity> _topScores = [];
  bool _isLoading = false;

  // Local fallback leaderboard
  final List<GameScoreEntity> _localScores = [];

  GamesProvider({required this.firestoreService});

  List<GameScoreEntity> get topScores => _topScores;
  bool get isLoading => _isLoading;

  void syncUser(String? userId, String? userName) {
    _userId = userId;
    _userName = userName ?? 'Player';
    _scoreSub?.cancel();
    _scoreSub = null;

    if (userId == null) {
      _topScores = [];
      notifyListeners();
      return;
    }

    if (FirebaseConfig.isFirebaseReady) {
      _isLoading = true;
      notifyListeners();
      _scoreSub = firestoreService.watchTopScores('memory_match').listen(
        (scores) {
          _topScores = scores;
          _isLoading = false;
          notifyListeners();
        },
        onError: (_) {
          _isLoading = false;
          _topScores = List.from(_localScores);
          notifyListeners();
        },
      );
    } else {
      if (_localScores.isEmpty) {
        final now = DateTime.now().millisecondsSinceEpoch;
        _localScores.addAll([
          GameScoreEntity(
            id: 'mock_s1',
            userId: 'user1',
            userName: 'Cuong Tran',
            gameType: 'memory_match',
            score: 950,
            timeSpentSeconds: 24,
            createdAt: now - 86400000,
          ),
          GameScoreEntity(
            id: 'mock_s2',
            userId: 'user2',
            userName: 'Tech Master',
            gameType: 'memory_match',
            score: 820,
            timeSpentSeconds: 35,
            createdAt: now - 43200000,
          ),
          GameScoreEntity(
            id: 'mock_s3',
            userId: 'user3',
            userName: 'Guest Star',
            gameType: 'memory_match',
            score: 740,
            timeSpentSeconds: 42,
            createdAt: now - 10000000,
          ),
        ]);
      }
      _topScores = List.from(_localScores);
      notifyListeners();
    }
  }

  Future<void> submitScore({
    required String gameType,
    required int score,
    required int timeSpentSeconds,
    String difficulty = 'normal',
  }) async {
    if (_userId == null) return;

    if (FirebaseConfig.isFirebaseReady) {
      await firestoreService.recordGameScore(
        userId: _userId!,
        userName: _userName,
        gameType: gameType,
        score: score,
        timeSpentSeconds: timeSpentSeconds,
        difficulty: difficulty,
      );
    } else {
      final now = DateTime.now().millisecondsSinceEpoch;
      final newScore = GameScoreEntity(
        id: 'mock_s_$now',
        userId: _userId!,
        userName: _userName,
        gameType: gameType,
        score: score,
        timeSpentSeconds: timeSpentSeconds,
        difficulty: difficulty,
        createdAt: now,
      );
      _localScores.add(newScore);
      _localScores.sort((a, b) => b.score.compareTo(a.score));
      _topScores = List.from(_localScores);
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _scoreSub?.cancel();
    super.dispose();
  }
}
