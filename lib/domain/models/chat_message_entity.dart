class ChatMessageEntity {
  final String id;
  final String senderId;
  final String senderEmail;
  final String senderName;
  final String? receiverId; // null or 'public' for community, or other user's id for 1-1
  final String? receiverName;
  final String text;
  final int createdAt;
  final bool isRead;

  const ChatMessageEntity({
    required this.id,
    required this.senderId,
    required this.senderEmail,
    required this.senderName,
    this.receiverId,
    this.receiverName,
    required this.text,
    required this.createdAt,
    this.isRead = false,
  });

  bool get isPublic => receiverId == null || receiverId == 'public';

  Map<String, dynamic> toMap() => {
    'id': id,
    'senderId': senderId,
    'senderEmail': senderEmail,
    'senderName': senderName,
    'receiverId': receiverId ?? 'public',
    'receiverName': receiverName,
    'text': text,
    'createdAt': createdAt,
    'isRead': isRead,
  };

  factory ChatMessageEntity.fromMap(String docId, Map<String, dynamic> map) =>
      ChatMessageEntity(
        id: docId,
        senderId: map['senderId'] as String? ?? '',
        senderEmail: map['senderEmail'] as String? ?? '',
        senderName: map['senderName'] as String? ?? (map['senderEmail'] as String? ?? 'User').split('@').first,
        receiverId: map['receiverId'] as String? ?? 'public',
        receiverName: map['receiverName'] as String?,
        text: map['text'] as String? ?? '',
        createdAt: (map['createdAt'] as num?)?.toInt() ?? 0,
        isRead: map['isRead'] as bool? ?? false,
      );

  ChatMessageEntity copyWith({
    String? id,
    String? senderId,
    String? senderEmail,
    String? senderName,
    String? receiverId,
    String? receiverName,
    String? text,
    int? createdAt,
    bool? isRead,
  }) =>
      ChatMessageEntity(
        id: id ?? this.id,
        senderId: senderId ?? this.senderId,
        senderEmail: senderEmail ?? this.senderEmail,
        senderName: senderName ?? this.senderName,
        receiverId: receiverId ?? this.receiverId,
        receiverName: receiverName ?? this.receiverName,
        text: text ?? this.text,
        createdAt: createdAt ?? this.createdAt,
        isRead: isRead ?? this.isRead,
      );
}
