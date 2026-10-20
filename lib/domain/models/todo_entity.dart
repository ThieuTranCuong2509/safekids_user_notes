class TodoEntity {
  final String id;
  final String userId;
  final String title;
  final bool isCompleted;
  final String priority; // low, medium, high
  final int? dueDate;
  final String? teamId;
  final String? assigneeName;
  final int createdAt;
  final int updatedAt;

  const TodoEntity({
    required this.id,
    required this.userId,
    required this.title,
    this.isCompleted = false,
    this.priority = 'medium',
    this.dueDate,
    this.teamId,
    this.assigneeName,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'userId': userId,
    'title': title,
    'isCompleted': isCompleted,
    'priority': priority,
    'dueDate': dueDate,
    if (teamId != null) 'teamId': teamId,
    if (assigneeName != null) 'assigneeName': assigneeName,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
  };

  factory TodoEntity.fromMap(String key, Map<dynamic, dynamic> map) {
    return TodoEntity(
      id: key,
      userId: map['userId']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      isCompleted: map['isCompleted'] == true,
      priority: map['priority']?.toString() ?? 'medium',
      dueDate: (map['dueDate'] as num?)?.toInt(),
      teamId: map['teamId']?.toString(),
      assigneeName: map['assigneeName']?.toString(),
      createdAt: (map['createdAt'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch,
      updatedAt: (map['updatedAt'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch,
    );
  }

  TodoEntity copyWith({
    String? id,
    String? userId,
    String? title,
    bool? isCompleted,
    String? priority,
    int? dueDate,
    String? teamId,
    String? assigneeName,
    int? createdAt,
    int? updatedAt,
  }) {
    return TodoEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      teamId: teamId ?? this.teamId,
      assigneeName: assigneeName ?? this.assigneeName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TodoEntity &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          userId == other.userId &&
          title == other.title &&
          isCompleted == other.isCompleted &&
          priority == other.priority &&
          teamId == other.teamId;

  @override
  int get hashCode => Object.hash(id, userId, title, isCompleted, priority, teamId);
}
