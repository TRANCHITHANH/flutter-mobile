// chịu trách nhiệm: xử lý logic nghiệp vụ, tính toán và truy xuất CSDL

class Task {
  //chứa data type & thuộc tính như: mã định danh, tiêu đề, độ ưu tiên, danh mục,trạng thái hoàn tích và ngày giờ.
  String id, title, priority, category;
  bool isCompleted;
  DateTime date;

  //constructor: truy cập tham chiếu đến nhằm sử dụng tài nguyên của thuộc tính đó.
  Task({required this.id,// VD: create new task thì bắt buộc(required) phải đưa dữ liệu vào ko đc bỏ qua
        required this.title,
        required this.date,

        this.isCompleted = false,// nếu bỏ qua thì lấy giá trị mặc định
        this.priority = 'Medium',
        this.category = 'Work'});
  //do bất đồng bộ giữa RAM và ổ cứng -->nên sinh ra hàm chuyển đổi dữ liệu (data serialization) giữa 2 bên key - value
  //1. toMap() tuần tự hoá (Serialize)
  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'isCompleted': isCompleted ? 1 : 0, // nếu IsCompleted true thì lưu 1, false thì lưu 0 // toán tử 3 ngôi //
    'priority': priority,
    'date': date.toIso8601String(), // time -> string
    'category': category};

  //2. fromMap(): giải tuần tự hoá (Deserialize)
  factory Task.fromMap(Map<String, dynamic> map) => Task(
    id: map['id'],
    title: map['title'],
    isCompleted: (map['isCompleted'] == 1), // kiểm tra xem giá trị trong map == 1 thì trả về true, ngc lại false
    priority: map['priority'],
    date: DateTime.parse(map['date']), //hàm Datetime.parse đọc chuỗi văn bản --> đối tượng đồng hồ
    category: map['category'],
  );
}