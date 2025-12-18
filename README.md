# tranchithanh_2280602962

Đồ án môn học Lập trình thiết bị di động, xây dựng ứng dụng quản lý công việc cá nhân bằng Flutter.

🚀 Chức năng đã hoàn thiện (Features)

### 1. Quản lý công việc (Task Management)
- [x] **Thêm mới (Add):** Nhập tên, chọn giờ, mức độ ưu tiên (Priority) và danh mục (Category).
- [x] **Sửa (Edit):** Cập nhật lại thông tin khi sai sót (bấm vào tên công việc để sửa).
- [x] **Xóa (Delete):** Vuốt sang trái (Swipe) hoặc bấm icon xóa để loại bỏ công việc.
- [x] **Đánh dấu (Toggle):** Check vào ô tròn để đánh dấu hoàn thành/chưa hoàn thành.

### 2. Giao diện & Trải nghiệm (UI/UX)
- [x] **Dark Mode:** Giao diện nền đen hiện đại, dịu mắt.
- [x] **Lịch (Calendar View):** Tích hợp `table_calendar` để xem và chọn ngày làm việc.
- [x] **Mức độ ưu tiên (Visual Priority):**
  - 🔴 **High:** Viền đỏ.
  - 🟠 **Medium:** Viền cam.
  - 🟢 **Low:** Viền xanh.

### 3. Cơ sở dữ liệu (Database)
- [x] **SQLite Offline:** Sử dụng thư viện `sqflite` để lưu trữ dữ liệu vĩnh viễn trên máy (tắt app không mất dữ liệu).
- [x] **State Management:** Sử dụng `Provider` để quản lý trạng thái ứng dụng mượt mà.

## 🛠 Công nghệ sử dụng
- **Ngôn ngữ:** Dart
- **Framework:** Flutter
- **Thư viện chính:**
  - `sqflite`: Database.
  - `provider`: Quản lý trạng thái.
  - `table_calendar`: Hiển thị lịch.
  - `intl`: Định dạng ngày giờ.

---
**Thực hiện bởi:** Trần Chí Thanh (TRANCHITHANH)
