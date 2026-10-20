class NoteEntity {
  final String id;
  final String userId;
  final String title;
  final String content;
  final String categoryId;
  final String colorTag;
  final bool isPinned;
  final bool isArchived;
  final int createdAt;
  final int updatedAt;

  const NoteEntity({
    required this.id,
    required this.userId,
    required this.title,
    required this.content,
    this.categoryId = 'general',
    this.colorTag = '#FFFFFF',
    this.isPinned = false,
    this.isArchived = false,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'userId': userId,
    'title': title,
    'content': content,
    'categoryId': categoryId,
    'colorTag': colorTag,
    'isPinned': isPinned,
    'isArchived': isArchived,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
  };

  factory NoteEntity.fromMap(String key, Map<dynamic, dynamic> map) {
    return NoteEntity(
      id: key,
      userId: map['userId']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      content: map['content']?.toString() ?? '',
      categoryId: map['categoryId']?.toString() ?? 'general',
      colorTag: map['colorTag']?.toString() ?? '#FFFFFF',
      isPinned: map['isPinned'] == true,
      isArchived: map['isArchived'] == true,
      createdAt: (map['createdAt'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch,
      updatedAt: (map['updatedAt'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch,
    );
  }

  NoteEntity copyWith({
    String? id,
    String? userId,
    String? title,
    String? content,
    String? categoryId,
    String? colorTag,
    bool? isPinned,
    bool? isArchived,
    int? createdAt,
    int? updatedAt,
  }) {
    return NoteEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      content: content ?? this.content,
      categoryId: categoryId ?? this.categoryId,
      colorTag: colorTag ?? this.colorTag,
      isPinned: isPinned ?? this.isPinned,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NoteEntity &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          userId == other.userId &&
          title == other.title &&
          content == other.content &&
          categoryId == other.categoryId &&
          colorTag == other.colorTag &&
          isPinned == other.isPinned &&
          isArchived == other.isArchived &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    title,
    content,
    categoryId,
    colorTag,
    isPinned,
    isArchived,
    createdAt,
    updatedAt,
  );
}
