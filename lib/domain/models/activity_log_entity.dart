class ActivityLogEntity {
  final String id;
  final String userId;
  final String action; // 'create_note', 'delete_note', 'complete_todo', 'game_played'
  final String title;
  final String details;
  final int createdAt;

  const ActivityLogEntity({
    required this.id,
    required this.userId,
    required this.action,
    required this.title,
    this.details = '',
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'userId': userId,
    'action': action,
    'title': title,
    'details': details,
    'createdAt': createdAt,
  };

  factory ActivityLogEntity.fromMap(String key, Map<dynamic, dynamic> map) {
    return ActivityLogEntity(
      id: key,
      userId: map['userId']?.toString() ?? '',
      action: map['action']?.toString() ?? 'general',
      title: map['title']?.toString() ?? '',
      details: map['details']?.toString() ?? '',
      createdAt: (map['createdAt'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch,
    );
  }

  ActivityLogEntity copyWith({
    String? id,
    String? userId,
    String? action,
    String? title,
    String? details,
    int? createdAt,
  }) {
    return ActivityLogEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      action: action ?? this.action,
      title: title ?? this.title,
      details: details ?? this.details,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActivityLogEntity &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          userId == other.userId &&
          title == other.title;

  @override
  int get hashCode => Object.hash(id, userId, action, title);
}
