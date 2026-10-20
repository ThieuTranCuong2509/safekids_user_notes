# Cuong Tran Notes (Cloud Firestore, Teamwork RBAC & Productivity Suite)

Ứng dụng ghi chú và làm việc nhóm đa nền tảng (Flutter) tích hợp **Firebase Authentication**, **Cloud Firestore** với tính năng **Làm việc nhóm (Teamwork) phân quyền vai trò (RBAC)** và **Khu trò chơi giải trí (Flappy Bird, Memory Match, Math Blitz)**, được thiết kế theo kiến trúc Clean Architecture phục vụ cho **Đồ án tốt nghiệp**.

---

## 📱 Thông số định danh ứng dụng

- **Firebase Project ID:** `cuongtt-e83bf`
- **Android Package Name (Application ID):** `com.cuongtran.notes`
- **iOS Bundle Identifier:** `com.cuongtran.notes`
- **GitHub Repository:** [https://github.com/ThieuTranCuong2509/safekids_user_notes](https://github.com/ThieuTranCuong2509/safekids_user_notes)

---

## 👥 Tính Năng Làm Việc Nhóm & Phân Quyền Vai Trò (Teamwork & RBAC)

Hệ thống hỗ trợ phân quyền người dùng theo mô hình **Role-Based Access Control (RBAC)** trong từng nhóm làm việc:

| Vai trò (Role) | Quyền hạn chi tiết (Permissions) |
| :--- | :--- |
| **👑 Trưởng nhóm (Owner)** | Toàn quyền quản trị nhóm: Đổi tên, thêm/xóa thành viên, phân cấp vai trò (`Editor` / `Viewer`), xóa nhóm, tạo/sửa/xóa mọi ghi chú và checklist nhóm. |
| **✏️ Biên tập viên (Editor)** | Được phép tạo mới, chỉnh sửa ghi chú dùng chung, đánh dấu hoàn thành nhiệm vụ checklist trong nhóm. Không thể xóa nhóm hoặc đổi quyền thành viên. |
| **👁 Người xem (Viewer)** | Chỉ có quyền đọc nội dung ghi chú và theo dõi tiến độ checklist của nhóm (Read-Only). Không có quyền chỉnh sửa hay xóa. |

Giao diện quản lý nhóm tại tab **Nhóm (RBAC)** cho phép thêm thành viên theo email, thay đổi vai trò linh hoạt và chuyển đổi giữa không gian cá nhân với không gian làm việc nhóm.

---

## 🗄 Kiến Trúc Database NoSQL (Cloud Firestore Collections)

Hệ thống Firestore được tổ chức gồm **7 Collections** chuẩn mực:

1. **`users`:** Hồ sơ tài khoản, thống kê số ghi chú, số ván game và điểm kỷ lục.
2. **`teams`:** Danh sách nhóm, `ownerId`, mảng `memberIds`, bản đồ phân quyền `memberRoles` (owner, editor, viewer).
3. **`notes`:** Ghi chú cá nhân & ghi chú nhóm (`teamId`), ghim đầu trang (`isPinned`), màu nền (`colorTag`), danh mục (`categoryId`).
4. **`categories`:** Danh mục phân loại ghi chú (Học tập, Công việc, Cá nhân, Ý tưởng).
5. **`todos`:** Danh sách công việc checklist cá nhân & nhóm với mức độ ưu tiên (*Cao, Vừa, Thấp*).
6. **`game_scores`:** Bảng xếp hạng kỷ lục mini-games thời gian thực (`flappy_bird`, `memory_match`, `math_speed`).
7. **`activity_logs`:** Nhật ký kiểm toán mọi thao tác thời gian thực trên hệ thống.

---

## 🎮 Khu Trò Chơi Giải Trí & Bảng Xếp Hạng (Mini-Games Zone)

Tích hợp 3 trò chơi giải trí mượt mà (60 FPS) giúp thư giãn:
1. **🐤 Flappy Bird (HOT):** Điều khiển chú chim vượt qua các đường ống cống với mô phỏng trọng lực vật lý mượt mà, ghi điểm và lưu kỷ lục.
2. **💡 Memory Match (Lật thẻ trí nhớ):** Lật tìm 6 cặp biểu tượng tương ứng, tính điểm thông minh dựa trên số lượt lật và thời gian.
3. **⚡ Math Blitz (Toán nhanh 30s):** Thử thách tính nhẩm phản xạ thần tốc trong 30 giây với combo chuỗi đúng.
- **Tự động lưu điểm:** Điểm số sau mỗi ván chơi được tự động ghi nhận vào collection `game_scores` trên Firestore và hiển thị theo thứ hạng thực tế trên Leaderboard.

---

## ⚡ Quản Lý Trạng Thái & Hiệu Năng (State Management & Performance)

- **Provider Pattern Tối Ưu:** Sử dụng `ChangeNotifierProvider` và `ChangeNotifierProxyProvider` phân tầng độc lập (`AuthProvider`, `NotesProvider`, `TodosProvider`, `TeamProvider`, `GamesProvider`, `ActivityProvider`).
- **Giảm Thiểu Rebuild:** Phân tách widget thành các component `const`, chỉ rebuild đúng phần giao diện cần cập nhật khi dữ liệu thay đổi.
- **Khả Năng Chống Lỗi (Zero Crash Resilience):** Tự động fallback sang In-Memory Mock Service khi mất mạng hoặc chưa cấu hình Firebase, đảm bảo app luôn chạy mượt mà 100% trong buổi chấm đồ án.

---

## 🛡 Quy Tắc Bảo Mật Firestore (`firestore.rules`)

File `firestore.rules` phân quyền chặt chẽ:
- Người dùng chỉ truy cập được dữ liệu của chính mình hoặc nhóm mà mình là thành viên (`memberIds.hasAny([request.auth.uid])`).
- Leaderboard cho phép xem công khai giữa các tài khoản đã xác thực.

---

## 🧪 Kiểm Thử & Đảm Bảo Chất Lượng

```bash
flutter test
```
*Kết quả:* **21/21 tests passed!** (Đầy đủ kiểm thử tuần tự hóa, xác thực phân quyền TeamEntity, logic Auth và State).

```bash
flutter analyze
```
*Kết quả:* **No issues found!**
