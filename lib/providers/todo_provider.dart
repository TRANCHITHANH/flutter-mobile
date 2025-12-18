import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/task_model.dart';

//Class TodoProvider như Controller đứng giữa Model (Task) và View (Giao diện) --> quản lý trạng thái và thao tác với dữ liệu
// Biến Class này thành 1 trạm sóng, khi nó kế thừa có khả năng dùng loa notifyListeners(): hét cho toàn bộ ứng dụng mỗi khi dữ liệu thay đổi    XXX đơ, update new task
class TodoProvider extends ChangeNotifier {
  // Biến lưu trữ kết nối đến database SQLite: lúc mở app DB chưa kịp load nên để biến này là null được (?), sau khi hàm init() chạy xong thì nó sẽ có giá trị, _: private
  Database? _database; 

  //SQLite nằm 0 ổ cứng (lấy chậm) >< biến _tasks lưu trữ tạm 0 RAM (lấy nhanh) nghĩa là:
  //Khi open app thì load data từ SQLite lên _tasks, khi thao tác CRUD thì chỉ cần thao tác trên _tasks rồi đồng bộ ngược lại SQLite
  List<Task> _tasks = [];

  //_tasks private --> tạo cổng phụ getter tên là tasks, chỉ cho phép nhìn và lấy dữ liệu qua cổng tasks
  List<Task> get tasks => _tasks;

  // Tạo bảng
  final String tableName = 'tasks';

  // Khởi tạo Database SQLite
  Future<void> init() async {
    // Hàm getDatabasesPath() hỏi hệ điều hành xem thư mục app nằm ở đâu --> join() nối tên file db vào đường dẫn thư mục app (đường dẫn tuyệt đối)
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'calendar_database.db');

    //Test path ? nếu đã thì mở luôn 
    _database = await openDatabase(
      path,
      version: 1,// ví dụ hôm nay lưu tên & ngày ... tháng sau: lưu thêm hình ảnh -->version: 2, tự động chạy hàm onUpgrade thêm cột  & ko mất dữ liệu cũ

      onCreate: (db, version) { //chưa thì ra lệnh SQLite tạo bảng (giống tạo Sheet trong Excel)
        return db.execute(
          'CREATE TABLE $tableName(id TEXT PRIMARY KEY, title TEXT, isCompleted INTEGER, priority TEXT, date TEXT, category TEXT)',
        );
      },

    );

    await _loadTasks(); // Tải dữ liệu lên sau khi mở DB
  }

  // Hàm đọc dữ liệu từ SQL lên List(hiển thị trên màn hình)
  Future<void> _loadTasks() async {
    final List<Map<String, dynamic>> maps = await _database!.query(tableName);
    _tasks = List.generate(maps.length, (i) => Task.fromMap(maps[i]));
    notifyListeners();
  }

  // Thêm Task
  Future<void> addTask(String title, String priority, DateTime date, String cat) async {
    final newTask = Task(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      priority: priority,
      date: date,
      category: cat
    );

    await _database!.insert(
      tableName,
      newTask.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    
    _tasks.add(newTask);
    notifyListeners();
  }

  // Cập nhật trạng thái
  Future<void> toggle(String id) async {
    final index = _tasks.indexWhere((t) => t.id == id);
    if (index != -1) {
      _tasks[index].isCompleted = !_tasks[index].isCompleted;
      
      await _database!.update(
        tableName,
        _tasks[index].toMap(),
        where: 'id = ?',
        whereArgs: [id],
      );
      
      notifyListeners();
    }
  }

  // Xóa Task
  Future<void> delete(String id) async {
    await _database!.delete(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
    
    _tasks.removeWhere((t) => t.id == id);
    notifyListeners();
  }

  // Cập nhật Task
  Future<void> updateTask(Task task) async {
    await _database!.update(
      tableName,
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
    
    // Cập nhật list local để giao diện tự đổi
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      _tasks[index] = task;
      notifyListeners();
    }
  }
}