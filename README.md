# Cuong Tran Notes (Cloud Firestore & Productivity Suite)

Ứng dụng ghi chú và quản lý công việc đa nền tảng (Flutter) tích hợp **Firebase Authentication** và **Cloud Firestore**, được phát triển bài bản theo mô hình Clean Architecture phục vụ cho **Đồ án tốt nghiệp**.

---

## 📱 Thông số định danh ứng dụng (Package & Firebase Project)

- **Firebase Project ID:**
  ```text
  cuongtt-e83bf
  ```
- **Android Package Name (Application ID):**
  ```text
  com.cuongtran.notes
  ```
- **iOS Bundle Identifier:**
  ```text
  com.cuongtran.notes
  ```

---

## 🗄 Kiến Trúc Database: 6 Đối Tượng / 6 Bảng (Cloud Firestore)

Hệ thống cơ sở dữ liệu NoSQL trên Cloud Firestore bao gồm **6 Collections** chuyên biệt, đảm bảo tính mở rộng, bảo mật và toàn vẹn dữ liệu:

1. **`users` (Hồ sơ người dùng):**
   - Lưu trữ `id`, `email`, `displayName`, `totalNotes`, `gamesPlayed`, `highestScore`, `createdAt`, `lastLoginAt`.
   - Quản lý trạng thái và hồ sơ cá nhân.

2. **`notes` (Ghi chú Firestore):**
   - Lưu trữ `id`, `userId`, `title`, `content`, `categoryId`, `colorTag`, `isPinned`, `isArchived`, `createdAt`, `updatedAt`.
   - Hỗ trợ ghim lên đầu, phân loại danh mục, gắn thẻ màu sắc và đồng bộ real-time.

3. **`categories` (Danh mục phân loại):**
   - Lưu trữ `id`, `userId`, `name` (Học tập, Công việc, Cá nhân, Ý tưởng), `colorHex`, `iconName`.

4. **`todos` (Nhiệm vụ & Checklist):**
   - Lưu trữ `id`, `userId`, `title`, `isCompleted`, `priority` (low, medium, high), `dueDate`, `createdAt`, `updatedAt`.
   - Giúp sinh viên quản lý tiến độ công việc, đồ án theo mức độ ưu tiên.

5. **`game_scores` (Điểm số Mini-Games & Leaderboard):**
   - Lưu trữ `id`, `userId`, `userName`, `gameType` (`memory_match`, `math_speed`), `score`, `timeSpentSeconds`, `difficulty`, `createdAt`.
   - Bảng xếp hạng điểm số thời gian thực giữa các người dùng.

6. **`activity_logs` (Nhật ký hoạt động hệ thống):**
   - Lưu trữ `id`, `userId`, `action` (`create_note`, `update_note`, `delete_note`, `complete_todo`, `play_game`), `title`, `details`, `createdAt`.
   - Phục vụ kiểm toán, hiển thị lịch sử hoạt động trực quan trong tab Hồ sơ.

---

## 🎮 Khu Vực Giải Trí & Mini-Games (Relaxation Zone)

Ứng dụng tích hợp sẵn 2 mini-games thú vị giúp người dùng giải tỏa căng thẳng:
1. **Memory Match (Lật thẻ trí nhớ):** Trò chơi lật 12 thẻ (6 cặp biểu tượng) rèn luyện trí nhớ ngắn hạn. Tự động tính điểm dựa trên thời gian và số lượt lật.
2. **Math Blitz (Toán nhanh 30s):** Thử thách tính nhẩm phản xạ thần tốc trong 30 giây với chuỗi combo điểm số cao.
- **Tự động lưu điểm:** Điểm số sau mỗi ván chơi được tự động đẩy lên collection `game_scores` trên Firestore để vinh danh trên Bảng xếp hạng.

---

## 🛡 Quy Tắc Bảo Mật Firestore (`firestore.rules`)

File `firestore.rules` đã được tạo sẵn tại thư mục gốc với các quy tắc bảo mật nghiêm ngặt:
- Mỗi người dùng chỉ có quyền đọc/ghi dữ liệu của chính mình (`request.auth.uid == userId`).
- Riêng collection `game_scores` cho phép tất cả tài khoản đã xác thực được đọc (để hiển thị Bảng xếp hạng công khai), nhưng chỉ chính chủ mới được tạo/sửa điểm của mình.

---

## 🚀 Các Bước Hoàn Tất Kết Nối Firebase (cuongtt-e83bf)

### Bước 1: Đăng ký Android App trong Project `cuongtt-e83bf`
1. Truy cập [Firebase Console](https://console.firebase.google.com/) $\rightarrow$ Chọn project **`cuongtt-e83bf`**.
2. Nhấn vào biểu tượng **Android** (Thêm ứng dụng).
3. Điền Package Name:
   ```text
   com.cuongtran.notes
   ```
4. Đặt App Nickname: `Cuong Tran Notes`.
5. Nhấn **Register app** $\rightarrow$ Tải file `google-services.json` về máy.
6. Copy file `google-services.json` vào thư mục:
   ```text
   android/app/google-services.json
   ```

### Bước 2: Bật Firebase Authentication & Cloud Firestore
1. **Authentication:**
   - Vào mục **Build** $\rightarrow$ **Authentication** $\rightarrow$ **Sign-in method** $\rightarrow$ Bật **Email/Password** $\rightarrow$ Lưu.
2. **Firestore Database:**
   - Vào mục **Build** $\rightarrow$ **Firestore Database** $\rightarrow$ Nhấn **Create database**.
   - Chọn vị trí cơ sở dữ liệu: `asia-southeast1 (Singapore)`.
   - Vào tab **Rules**, dán toàn bộ nội dung từ file `firestore.rules` và bấm **Publish**.

---

## 🧪 Kiểm Thử & Đảm Bảo Chất Lượng

Dự án có độ phủ kiểm thử đầy đủ:
```bash
flutter test
```
*Kết quả:* **20/20 tests passed** (Bao gồm kiểm thử tuần tự hóa cho toàn bộ 6 thực thể dữ liệu, Auth, Notes, và Smoke Test UI).

Kiểm tra cú pháp và chất lượng mã nguồn:
```bash
flutter analyze
```
*Kết quả:* **No issues found!**
