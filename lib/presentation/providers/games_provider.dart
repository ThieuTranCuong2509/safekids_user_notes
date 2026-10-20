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

  final List<GameScoreEntity> _localScores = [];

  GamesProvider({required this.firestoreService});

  List<GameScoreEntity> get topScores => _topScores;
  bool get isLoading => _isLoading;

  static List<GameScoreEntity> _defaultLeaderboard() {
    final now = DateTime.now().millisecondsSinceEpoch;
    return [
      GameScoreEntity(
        id: 'mock_s1',
        userId: 'user1',
        userName: 'Cuong Tran (Pro)',
        gameType: 'flappy_bird',
        score: 120,
        timeSpentSeconds: 45,
        createdAt: now - 3600000,
      ),
      GameScoreEntity(
        id: 'mock_s2',
        userId: 'user2',
        userName: 'Tech Master',
        gameType: 'flappy_bird',
        score: 80,
        timeSpentSeconds: 32,
        createdAt: now - 7200000,
      ),
      GameScoreEntity(
        id: 'mock_s3',
        userId: 'user3',
        userName: 'Guest Star',
        gameType: 'flappy_bird',
        score: 50,
        timeSpentSeconds: 20,
        createdAt: now - 10000000,
      ),
    ];
  }

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

    if (_localScores.isEmpty) {
      _localScores.addAll(_defaultLeaderboard());
    }
    _topScores = List.from(_localScores);
    _isLoading = false;
    notifyListeners();

    if (FirebaseConfig.isFirebaseReady) {
      _scoreSub = firestoreService.watchTopScores('flappy_bird').listen(
        (scores) {
          if (scores.isNotEmpty) {
            _topScores = scores;
          }
          _isLoading = false;
          notifyListeners();
        },
        onError: (_) {
          _isLoading = false;
          if (_topScores.isEmpty) {
            _topScores = List.from(_localScores);
          }
          notifyListeners();
        },
      );
    }
  }

  void filterGame(String gameType) {
    if (FirebaseConfig.isFirebaseReady) {
      _scoreSub?.cancel();
      _isLoading = true;
      notifyListeners();
      _scoreSub = firestoreService.watchTopScores(gameType).listen(
        (scores) {
          _topScores = scores.isNotEmpty
              ? scores
              : _localScores.where((s) => s.gameType == gameType).toList();
          _isLoading = false;
          notifyListeners();
        },
        onError: (_) {
          _isLoading = false;
          _topScores = _localScores.where((s) => s.gameType == gameType).toList();
          notifyListeners();
        },
      );
    } else {
      _topScores = _localScores.where((s) => s.gameType == gameType).toList();
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

    final now = DateTime.now().millisecondsSinceEpoch;
    final newScore = GameScoreEntity(
      id: 'score_$now',
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
    _topScores = _localScores.where((s) => s.gameType == gameType).toList();
    notifyListeners();

    if (FirebaseConfig.isFirebaseReady) {
      try {
        await firestoreService.recordGameScore(
          userId: _userId!,
          userName: _userName,
          gameType: gameType,
          score: score,
          timeSpentSeconds: timeSpentSeconds,
          difficulty: difficulty,
        );
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _scoreSub?.cancel();
    super.dispose();
  }
}
