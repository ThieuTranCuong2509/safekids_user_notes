import 'package:flutter/material.dart';
import 'table_detail_screen.dart';

class DatabaseTablesConfig {
  static const List<TableMetadata> allTables = [
    TableMetadata(
      id: 'users',
      tableName: '1. users',
      title: 'Hồ Sơ & Danh Sách Người Dùng',
      subtitle: 'Quản lý thông tin tài khoản, email, UID, số lượng ghi chú, game, trạng thái xác thực 2FA',
      icon: Icons.people_alt_rounded,
      color: Colors.blue,
      securityRule: '''match /users/{userId} {
  allow read: if request.auth != null;
  allow write: if request.auth != null 
    && request.auth.uid == userId;
}''',
      schema: [
        TableSchemaField(fieldName: 'id', fieldType: 'String', description: 'Mã định danh duy nhất (Firebase Auth UID)'),
        TableSchemaField(fieldName: 'email', fieldType: 'String', description: 'Địa chỉ email đăng ký tài khoản'),
        TableSchemaField(fieldName: 'displayName', fieldType: 'String', description: 'Tên hiển thị người dùng hoặc nickname', isRequired: false),
        TableSchemaField(fieldName: 'totalNotes', fieldType: 'Number', description: 'Tổng số ghi chú đã tạo trong hệ thống'),
        TableSchemaField(fieldName: 'gamesPlayed', fieldType: 'Number', description: 'Tổng số lượt chơi mini-game'),
        TableSchemaField(fieldName: 'highestScore', fieldType: 'Number', description: 'Điểm số kỷ lục cao nhất'),
        TableSchemaField(fieldName: 'isTwoFactorEnabled', fieldType: 'Boolean', description: 'Trạng thái bật/tắt bảo mật 2 lớp (2FA)'),
        TableSchemaField(fieldName: 'twoFactorPin', fieldType: 'String', description: 'Mã PIN bảo mật xác thực 2 bước', isRequired: false),
        TableSchemaField(fieldName: 'createdAt', fieldType: 'Timestamp', description: 'Thời điểm tạo tài khoản'),
        TableSchemaField(fieldName: 'lastLoginAt', fieldType: 'Timestamp', description: 'Thời điểm đăng nhập gần nhất'),
      ],
    ),
    TableMetadata(
      id: 'notes',
      tableName: '2. notes',
      title: 'Ghi Chú Đám Mây & Nhóm',
      subtitle: 'Lưu trữ tiêu đề, nội dung ghi chú, nhãn màu, ghim ưu tiên và liên kết nhóm',
      icon: Icons.note_alt_rounded,
      color: Colors.purple,
      securityRule: '''match /notes/{noteId} {
  allow read: if request.auth != null 
    && (resource.data.userId == request.auth.uid 
        || resource.data.teamId != null);
  allow write: if request.auth != null 
    && (request.resource.data.userId == request.auth.uid 
        || resource.data.userId == request.auth.uid);
}''',
      schema: [
        TableSchemaField(fieldName: 'id', fieldType: 'String', description: 'Document ID tự sinh trên Cloud Firestore'),
        TableSchemaField(fieldName: 'userId', fieldType: 'String', description: 'UID của người dùng tạo ghi chú'),
        TableSchemaField(fieldName: 'title', fieldType: 'String', description: 'Tiêu đề của bản ghi chú'),
        TableSchemaField(fieldName: 'content', fieldType: 'String', description: 'Nội dung chi tiết của ghi chú'),
        TableSchemaField(fieldName: 'categoryId', fieldType: 'String', description: 'Mã danh mục phân loại (general, study, work...)'),
        TableSchemaField(fieldName: 'colorTag', fieldType: 'String', description: 'Mã màu HEX hiển thị nền ghi chú'),
        TableSchemaField(fieldName: 'isPinned', fieldType: 'Boolean', description: 'Trạng thái ghim ưu tiên lên đầu danh sách'),
        TableSchemaField(fieldName: 'teamId', fieldType: 'String', description: 'ID nhóm nếu chia sẻ cộng tác', isRequired: false),
        TableSchemaField(fieldName: 'createdAt', fieldType: 'Timestamp', description: 'Thời điểm tạo ghi chú (milliseconds)'),
        TableSchemaField(fieldName: 'updatedAt', fieldType: 'Timestamp', description: 'Thời điểm chỉnh sửa ghi chú gần nhất'),
      ],
    ),
    TableMetadata(
      id: 'categories',
      tableName: '3. categories',
      title: 'Danh Mục Phân Loại',
      subtitle: 'Phân nhóm chủ đề cho ghi chú và công việc học tập / làm việc',
      icon: Icons.folder_special_rounded,
      color: Colors.indigo,
      securityRule: '''match /categories/{catId} {
  allow read: if request.auth != null;
  allow write: if request.auth != null 
    && request.resource.data.userId == request.auth.uid;
}''',
      schema: [
        TableSchemaField(fieldName: 'id', fieldType: 'String', description: 'Document ID phân loại danh mục'),
        TableSchemaField(fieldName: 'userId', fieldType: 'String', description: 'UID người sở hữu danh mục'),
        TableSchemaField(fieldName: 'name', fieldType: 'String', description: 'Tên danh mục (Học tập, Công việc, Ý tưởng...)'),
        TableSchemaField(fieldName: 'colorHex', fieldType: 'String', description: 'Mã màu sắc nhận diện danh mục'),
        TableSchemaField(fieldName: 'iconName', fieldType: 'String', description: 'Tên icon hiển thị đại diện'),
        TableSchemaField(fieldName: 'createdAt', fieldType: 'Timestamp', description: 'Thời gian tạo danh mục'),
      ],
    ),
    TableMetadata(
      id: 'todos',
      tableName: '4. todos',
      title: 'Công Việc & Checklist',
      subtitle: 'Quản lý nhiệm vụ, tiến độ hoàn thành, độ ưu tiên và phân công',
      icon: Icons.checklist_rtl_rounded,
      color: Colors.teal,
      securityRule: '''match /todos/{todoId} {
  allow read: if request.auth != null 
    && (resource.data.userId == request.auth.uid 
        || resource.data.teamId != null);
  allow write: if request.auth != null;
}''',
      schema: [
        TableSchemaField(fieldName: 'id', fieldType: 'String', description: 'Document ID công việc'),
        TableSchemaField(fieldName: 'userId', fieldType: 'String', description: 'UID người tạo công việc'),
        TableSchemaField(fieldName: 'title', fieldType: 'String', description: 'Nội dung công việc cần hoàn thành'),
        TableSchemaField(fieldName: 'isCompleted', fieldType: 'Boolean', description: 'Trạng thái hoàn thành (true / false)'),
        TableSchemaField(fieldName: 'priority', fieldType: 'String', description: 'Mức độ ưu tiên (low, medium, high)'),
        TableSchemaField(fieldName: 'dueDate', fieldType: 'Timestamp', description: 'Hạn chót hoàn thành (deadline)', isRequired: false),
        TableSchemaField(fieldName: 'teamId', fieldType: 'String', description: 'ID nhóm nếu giao việc trong nhóm', isRequired: false),
        TableSchemaField(fieldName: 'assigneeName', fieldType: 'String', description: 'Tên người được giao nhiệm vụ', isRequired: false),
        TableSchemaField(fieldName: 'createdAt', fieldType: 'Timestamp', description: 'Thời điểm tạo công việc'),
        TableSchemaField(fieldName: 'updatedAt', fieldType: 'Timestamp', description: 'Thời điểm cập nhật gần nhất'),
      ],
    ),
    TableMetadata(
      id: 'teams',
      tableName: '5. teams',
      title: 'Nhóm & Phân Quyền RBAC',
      subtitle: 'Cộng tác làm việc theo nhóm với cơ chế phân quyền Role-Based Access Control',
      icon: Icons.groups_rounded,
      color: Colors.pink,
      securityRule: '''match /teams/{teamId} {
  allow read: if request.auth != null 
    && request.auth.uid in resource.data.memberIds;
  allow write: if request.auth != null 
    && (resource == null 
        || resource.data.memberRoles[request.auth.uid] == 'owner');
}''',
      schema: [
        TableSchemaField(fieldName: 'id', fieldType: 'String', description: 'ID nhóm làm việc'),
        TableSchemaField(fieldName: 'name', fieldType: 'String', description: 'Tên nhóm (ví dụ: Nhóm Đồ Án Tốt Nghiệp)'),
        TableSchemaField(fieldName: 'description', fieldType: 'String', description: 'Mô tả mục tiêu của nhóm'),
        TableSchemaField(fieldName: 'ownerId', fieldType: 'String', description: 'UID trưởng nhóm (Owner - toàn quyền)'),
        TableSchemaField(fieldName: 'memberIds', fieldType: 'Array<String>', description: 'Mảng danh sách UID thành viên tham gia'),
        TableSchemaField(fieldName: 'memberRoles', fieldType: 'Map<String, String>', description: 'Bảng phân quyền: Owner, Editor, Viewer'),
        TableSchemaField(fieldName: 'createdAt', fieldType: 'Timestamp', description: 'Thời gian thành lập nhóm'),
      ],
    ),
    TableMetadata(
      id: 'game_scores',
      tableName: '6. game_scores',
      title: 'Bảng Điểm Mini-Games',
      subtitle: 'Lưu trữ điểm số kỷ lục trò chơi Flappy Bird, Memory Match, Math Blitz',
      icon: Icons.sports_esports_rounded,
      color: Colors.deepOrange,
      securityRule: '''match /game_scores/{scoreId} {
  allow read: if request.auth != null;
  allow create: if request.auth != null;
}''',
      schema: [
        TableSchemaField(fieldName: 'id', fieldType: 'String', description: 'ID bản ghi điểm số'),
        TableSchemaField(fieldName: 'userId', fieldType: 'String', description: 'UID người chơi'),
        TableSchemaField(fieldName: 'userName', fieldType: 'String', description: 'Tên người chơi hiển thị bảng vàng'),
        TableSchemaField(fieldName: 'gameType', fieldType: 'String', description: 'Mã game: flappy_bird, memory_match, math_blitz'),
        TableSchemaField(fieldName: 'score', fieldType: 'Number', description: 'Điểm số đạt được'),
        TableSchemaField(fieldName: 'difficulty', fieldType: 'String', description: 'Độ khó thử thách (easy, normal, hard)'),
        TableSchemaField(fieldName: 'timeSpentSeconds', fieldType: 'Number', description: 'Thời gian chơi tính bằng giây'),
        TableSchemaField(fieldName: 'createdAt', fieldType: 'Timestamp', description: 'Thời điểm xác lập kỷ lục'),
      ],
    ),
    TableMetadata(
      id: 'activity_logs',
      tableName: '7. activity_logs',
      title: 'Nhật Ký Hoạt Động & Audit Trail',
      subtitle: 'Ghi nhận lịch sử thao tác hệ thống, bảo mật đăng nhập và quản trị',
      icon: Icons.history_toggle_off_rounded,
      color: Colors.brown,
      securityRule: '''match /activity_logs/{logId} {
  allow read, create: if request.auth != null 
    && request.resource.data.userId == request.auth.uid;
}''',
      schema: [
        TableSchemaField(fieldName: 'id', fieldType: 'String', description: 'ID bản ghi nhật ký hoạt động'),
        TableSchemaField(fieldName: 'userId', fieldType: 'String', description: 'UID người dùng thao tác'),
        TableSchemaField(fieldName: 'action', fieldType: 'String', description: 'Mã hành động (login, create_note, 2fa_enabled...)'),
        TableSchemaField(fieldName: 'title', fieldType: 'String', description: 'Tiêu đề mô tả thao tác ngắn gọn'),
        TableSchemaField(fieldName: 'details', fieldType: 'String', description: 'Nội dung chi tiết hoặc đối tượng tác động'),
        TableSchemaField(fieldName: 'createdAt', fieldType: 'Timestamp', description: 'Thời điểm phát sinh hành động'),
      ],
    ),
    TableMetadata(
      id: 'messages',
      tableName: '8. messages',
      title: 'Tin Nhắn Trò Chuyện Thời Gian Thực',
      subtitle: 'Lưu trữ tin nhắn trao đổi trong Kênh Cộng Đồng và Trò Chuyện 1-1',
      icon: Icons.chat_bubble_outline_rounded,
      color: Colors.cyan,
      securityRule: '''match /messages/{msgId} {
  allow read: if request.auth != null 
    && (resource.data.receiverId == 'public' 
        || resource.data.senderId == request.auth.uid 
        || resource.data.receiverId == request.auth.uid);
  allow create: if request.auth != null 
    && request.resource.data.senderId == request.auth.uid;
}''',
      schema: [
        TableSchemaField(fieldName: 'id', fieldType: 'String', description: 'ID tài liệu tin nhắn'),
        TableSchemaField(fieldName: 'senderId', fieldType: 'String', description: 'UID của người gửi tin nhắn'),
        TableSchemaField(fieldName: 'senderEmail', fieldType: 'String', description: 'Email của người gửi'),
        TableSchemaField(fieldName: 'senderName', fieldType: 'String', description: 'Tên hiển thị người gửi'),
        TableSchemaField(fieldName: 'receiverId', fieldType: 'String', description: "'public' (Kênh chung) hoặc UID người nhận (1-1)"),
        TableSchemaField(fieldName: 'receiverName', fieldType: 'String', description: 'Tên người nhận nếu chat 1-1', isRequired: false),
        TableSchemaField(fieldName: 'text', fieldType: 'String', description: 'Nội dung văn bản tin nhắn'),
        TableSchemaField(fieldName: 'createdAt', fieldType: 'Timestamp', description: 'Thời điểm gửi tin nhắn'),
        TableSchemaField(fieldName: 'isRead', fieldType: 'Boolean', description: 'Đánh dấu đã xem tin nhắn'),
      ],
    ),
  ];
}
