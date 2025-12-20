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

  bool _isLoggedIn = false;
  bool get isLoggedIn => _isLoggedIn;
  String _currentUsername = ""; // Lưu tên người đang đăng nhập
  String get currentUsername => _currentUsername;

  // Tạo bảng
  final String taskTable = 'tasks';
  final String userTable = 'users';

  // Khởi tạo Database SQLite
  Future<void> init() async {
    // Hàm getDatabasesPath() hỏi hệ điều hành xem thư mục app nằm ở đâu --> join() nối tên file db vào đường dẫn thư mục app (đường dẫn tuyệt đối)
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'ThayKhuyen.db');

    //Test path ? nếu đã thì mở luôn 
    _database = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async{
        // Create tasks table including username column for ownership
        await db.execute(
          'CREATE TABLE $taskTable(id TEXT PRIMARY KEY, title TEXT, isCompleted INTEGER, priority TEXT, date TEXT, category TEXT, username TEXT)',
        );
        await db.execute(
          'CREATE TABLE $userTable(username TEXT PRIMARY KEY, password TEXT)',
        );
      },
    );
  }
  // Đăng ký
  Future<bool> register(String user, String pass) async {
    try {
      await _database!.insert(userTable, {'username': user, 'password': pass});
      return true; // Thành công
    } catch (e) {
      return false;
    }
  }

  // Đăng nhập
  Future<bool> login(String user, String pass) async {
    List<Map> maps = await _database!.query(userTable,
        where: 'username = ? AND password = ?',
        whereArgs: [user, pass]);

    if (maps.isNotEmpty) {
      _isLoggedIn = true;
      _currentUsername = user;
      await _loadTasks(); // Đăng nhập xong thì tải task của người đó
      notifyListeners();
      return true;
    }
    return false;
  }

  // Đăng xuất
  void logout() {
    _isLoggedIn = false;
    _currentUsername = "";
    _tasks = []; // Xóa danh sách hiển thị
    notifyListeners();
  }

  Future<void> _loadTasks() async {
    // Chỉ lấy Task của người đang đăng nhập
    final List<Map<String, dynamic>> maps = await _database!.query(taskTable, 
      where: 'username = ?', 
      whereArgs: [_currentUsername]
    );
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

    // Khi lưu, nhớ lưu kèm username
    Map<String, dynamic> data = newTask.toMap();
    data['username'] = _currentUsername;

    await _database!.insert( taskTable, data, conflictAlgorithm: ConflictAlgorithm.replace,);
    _tasks.add(newTask);
    notifyListeners();
  }

  // Cập nhật trạng thái
  Future<void> toggle(String id) async {
    final index = _tasks.indexWhere((t) => t.id == id);
    if (index != -1) {
      _tasks[index].isCompleted = !_tasks[index].isCompleted;
      Map<String, dynamic> data = _tasks[index].toMap();
      data['username'] = _currentUsername;
      await _database!.update(taskTable, data, where: 'id = ?', whereArgs: [id]);
      notifyListeners();
    }
  }

  // Xóa Task
  Future<void> delete(String id) async {
    await _database!.delete(taskTable, where: 'id = ?', whereArgs: [id]);
    _tasks.removeWhere((t) => t.id == id);
    notifyListeners();
  }

  // Cập nhật Task
  Future<void> updateTask(Task task) async {
    Map<String, dynamic> data = task.toMap();
    data['username'] = _currentUsername; // Đảm bảo không mất chủ sở hữu
    await _database!.update(taskTable, data, where: 'id = ?', whereArgs: [task.id]);
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) { _tasks[index] = task; notifyListeners(); }
  }
}