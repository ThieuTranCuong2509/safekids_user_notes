class GameScoreEntity {
  final String id;
  final String userId;
  final String userName;
  final String gameType; // 'memory_match', 'math_speed'
  final int score;
  final int timeSpentSeconds;
  final String difficulty;
  final int createdAt;

  const GameScoreEntity({
    required this.id,
    required this.userId,
    required this.userName,
    required this.gameType,
    required this.score,
    required this.timeSpentSeconds,
    this.difficulty = 'normal',
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'userId': userId,
    'userName': userName,
    'gameType': gameType,
    'score': score,
    'timeSpentSeconds': timeSpentSeconds,
    'difficulty': difficulty,
    'createdAt': createdAt,
  };

  factory GameScoreEntity.fromMap(String key, Map<dynamic, dynamic> map) {
    return GameScoreEntity(
      id: key,
      userId: map['userId']?.toString() ?? '',
      userName: map['userName']?.toString() ?? 'Player',
      gameType: map['gameType']?.toString() ?? 'memory_match',
      score: (map['score'] as num?)?.toInt() ?? 0,
      timeSpentSeconds: (map['timeSpentSeconds'] as num?)?.toInt() ?? 0,
      difficulty: map['difficulty']?.toString() ?? 'normal',
      createdAt: (map['createdAt'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch,
    );
  }

  GameScoreEntity copyWith({
    String? id,
    String? userId,
    String? userName,
    String? gameType,
    int? score,
    int? timeSpentSeconds,
    String? difficulty,
    int? createdAt,
  }) {
    return GameScoreEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      gameType: gameType ?? this.gameType,
      score: score ?? this.score,
      timeSpentSeconds: timeSpentSeconds ?? this.timeSpentSeconds,
      difficulty: difficulty ?? this.difficulty,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GameScoreEntity &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          userId == other.userId &&
          score == other.score &&
          gameType == other.gameType;

  @override
  int get hashCode => Object.hash(id, userId, gameType, score);
}
