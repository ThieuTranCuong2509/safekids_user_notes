class CategoryEntity {
  final String id;
  final String userId;
  final String name;
  final String colorHex;
  final String iconName;
  final int createdAt;

  const CategoryEntity({
    required this.id,
    required this.userId,
    required this.name,
    this.colorHex = '#2196F3',
    this.iconName = 'folder',
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'userId': userId,
    'name': name,
    'colorHex': colorHex,
    'iconName': iconName,
    'createdAt': createdAt,
  };

  factory CategoryEntity.fromMap(String key, Map<dynamic, dynamic> map) {
    return CategoryEntity(
      id: key,
      userId: map['userId']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      colorHex: map['colorHex']?.toString() ?? '#2196F3',
      iconName: map['iconName']?.toString() ?? 'folder',
      createdAt: (map['createdAt'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch,
    );
  }

  CategoryEntity copyWith({
    String? id,
    String? userId,
    String? name,
    String? colorHex,
    String? iconName,
    int? createdAt,
  }) {
    return CategoryEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      colorHex: colorHex ?? this.colorHex,
      iconName: iconName ?? this.iconName,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CategoryEntity &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          userId == other.userId &&
          name == other.name;

  @override
  int get hashCode => Object.hash(id, userId, name);
}
