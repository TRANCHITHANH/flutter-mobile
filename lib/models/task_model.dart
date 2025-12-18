//Khởi tạo lớp task để lưu trữ thông tin công việc (from mẫu)
class Task {
  //Khai báo các thuộc tính như mã định danh, tiêu đề, độ ưu tiên, danh mục, trạng thái hoàn thành và ngày giờ
  String id, title, priority, category;
  bool isCompleted;
  DateTime date;

  //Hàm khởi tạo (constructor) với các tham số bắt buộc và tùy chọn mặc định
  Task({required this.id,
        required this.title,
        required this.date,

        this.isCompleted = false,
        this.priority = 'Medium',
        this.category = 'Work'});

  //SQLite nó ko hiểu data type chỉ hiểu chuỗi text và số (int, read) --> vì vậy cân 2 hàm để biên dịch:
  
  //1. Hàm toMap(): Dùng lưu vào database (Write) --> Hàm biến object Task thành Map (Key - Value)
  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'isCompleted': isCompleted ? 1 : 0,
    'priority': priority,
    'date': date.toIso8601String(),
    'category': category};

  //2. Hàm fromMap(): Dùng đọc từ database ra (Read) >--> Hàm biến Map (Key - Value) thêm với object Task
  factory Task.fromMap(Map<String, dynamic> map) => Task(
    id: map['id'],
    title: map['title'],
    isCompleted: (map['isCompleted'] == 1),
    priority: map['priority'],
    date: DateTime.parse(map['date']),
    category: map['category'],
  );
}