class TeamEntity {
  final String id;
  final String name;
  final String description;
  final String ownerId;
  final List<String> memberIds;
  final Map<String, String> memberRoles; // userId -> 'owner', 'editor', 'viewer'
  final int createdAt;
  final int updatedAt;

  const TeamEntity({
    required this.id,
    required this.name,
    this.description = '',
    required this.ownerId,
    required this.memberIds,
    this.memberRoles = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'description': description,
    'ownerId': ownerId,
    'memberIds': memberIds,
    'memberRoles': memberRoles,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
  };

  factory TeamEntity.fromMap(String key, Map<dynamic, dynamic> map) {
    return TeamEntity(
      id: key,
      name: map['name']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      ownerId: map['ownerId']?.toString() ?? '',
      memberIds: (map['memberIds'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      memberRoles: (map['memberRoles'] as Map<dynamic, dynamic>?)?.map(
            (k, v) => MapEntry(k.toString(), v.toString()),
          ) ??
          {},
      createdAt: (map['createdAt'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch,
      updatedAt: (map['updatedAt'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch,
    );
  }

  String getRole(String userId) {
    if (userId == ownerId) return 'owner';
    return memberRoles[userId] ?? 'viewer';
  }

  bool canEdit(String userId) {
    final role = getRole(userId);
    return role == 'owner' || role == 'editor';
  }

  bool isOwner(String userId) {
    return userId == ownerId || getRole(userId) == 'owner';
  }

  TeamEntity copyWith({
    String? id,
    String? name,
    String? description,
    String? ownerId,
    List<String>? memberIds,
    Map<String, String>? memberRoles,
    int? createdAt,
    int? updatedAt,
  }) {
    return TeamEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      ownerId: ownerId ?? this.ownerId,
      memberIds: memberIds ?? this.memberIds,
      memberRoles: memberRoles ?? this.memberRoles,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TeamEntity &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          ownerId == other.ownerId;

  @override
  int get hashCode => Object.hash(id, name, ownerId);
}
