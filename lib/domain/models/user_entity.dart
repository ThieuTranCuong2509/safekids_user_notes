class UserEntity {
  final String id;
  final String email;
  final String? displayName;
  final int totalNotes;
  final int gamesPlayed;
  final int highestScore;
  final int createdAt;
  final int lastLoginAt;

  const UserEntity({
    required this.id,
    required this.email,
    this.displayName,
    this.totalNotes = 0,
    this.gamesPlayed = 0,
    this.highestScore = 0,
    this.createdAt = 0,
    this.lastLoginAt = 0,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'email': email,
    'displayName': displayName,
    'totalNotes': totalNotes,
    'gamesPlayed': gamesPlayed,
    'highestScore': highestScore,
    'createdAt': createdAt,
    'lastLoginAt': lastLoginAt,
  };

  factory UserEntity.fromMap(Map<String, dynamic> map) => UserEntity(
    id: map['id'] as String? ?? '',
    email: map['email'] as String? ?? '',
    displayName: map['displayName'] as String?,
    totalNotes: (map['totalNotes'] as num?)?.toInt() ?? 0,
    gamesPlayed: (map['gamesPlayed'] as num?)?.toInt() ?? 0,
    highestScore: (map['highestScore'] as num?)?.toInt() ?? 0,
    createdAt: (map['createdAt'] as num?)?.toInt() ?? 0,
    lastLoginAt: (map['lastLoginAt'] as num?)?.toInt() ?? 0,
  );

  UserEntity copyWith({
    String? id,
    String? email,
    String? displayName,
    int? totalNotes,
    int? gamesPlayed,
    int? highestScore,
    int? createdAt,
    int? lastLoginAt,
  }) => UserEntity(
    id: id ?? this.id,
    email: email ?? this.email,
    displayName: displayName ?? this.displayName,
    totalNotes: totalNotes ?? this.totalNotes,
    gamesPlayed: gamesPlayed ?? this.gamesPlayed,
    highestScore: highestScore ?? this.highestScore,
    createdAt: createdAt ?? this.createdAt,
    lastLoginAt: lastLoginAt ?? this.lastLoginAt,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserEntity &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          email == other.email &&
          displayName == other.displayName &&
          totalNotes == other.totalNotes &&
          gamesPlayed == other.gamesPlayed &&
          highestScore == other.highestScore;

  @override
  int get hashCode => Object.hash(id, email, displayName, totalNotes, gamesPlayed, highestScore);
}
