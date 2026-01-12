import 'package:flutter/material.dart';// để dùng ChangeNotifier
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/task_model.dart';
class TodoProvider extends ChangeNotifier {// biến class này như 1 trạm sóng, khi CRUD -> vẽ lại màn hình thông qua notifyListeners()
  Database? _database; // kết nối -> file SQLite trong ổ cứng

  List<Task> _tasks = [];// list tạm trên RAM hiển thị nhanh lên màn hình
  List<Task> get tasks => _tasks; // cửa sổ getter để bên ngoài nhìn vào danh sách và lấy dữ liệu qua cổng tasks
  //mục đích: mở app thì copy dữ liệu từ ổ cứng -> RAM, màn hình chỉ cần đọc từ RAM cho mượt, khi thay đổi thì thay đổi trên RAM trước, sau đó đồng bộ lại ổ cứng
  //trạng thái đăng nhập: công tắc chuyển màn hình
  bool _isLoggedIn = false; // nếu F thì hiện màn hình đăng nhập >< T chuyển sang màn hình List Task
  bool get isLoggedIn => _isLoggedIn;
  String _currentUsername = ""; //tải List Task của user nào
  String get currentUsername => _currentUsername;

  // Tạo bảng
  final String taskTable = 'tasks';
  final String userTable = 'users';

  Future<void> init() async {
    // Hàm getDatabasesPath() ? hệ điều hành tìm thư mục app  >> Join >> file SQLite // thành đường dẫn tuyệt đối //
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'ThayKhuyen.db');

    //Test path ? nếu đã thì mở luôn 
    _database = await openDatabase(
      path,
      version: 1, //nếu thay đổi cấu trúc bảng thì tăng version lên
      onCreate: (db, version) async{
        await db.execute(
          'CREATE TABLE $taskTable(id TEXT PRIMARY KEY, title TEXT, isCompleted INTEGER, priority TEXT, date TEXT, category TEXT, username TEXT)',
        );
        await db.execute(
          'CREATE TABLE $userTable(username TEXT PRIMARY KEY, password TEXT)',
        );
      },
    );
  }
  // Đăng ký tài khoản: tương lai return T,F --> async, await(chờ)
  Future<bool> register(String user, String pass) async {// dữ liệu người dùng nhập vào 2 tham số 
    try {//thử 
      await _database!.insert(userTable, {'username': user, 'password': pass}); // DB đc mở nhét gt user, pass vào cột username, password
      return true; 
    } catch (e) {
      return false; // nếu lỗi
    }
  }

  // Đăng nhập
  Future<bool> login(String user, String pass) async {
    //DB sẽ tìm userTable với 2 cột username, password khớp với dữ liệu nhập vào
    List<Map> maps = await _database!.query(userTable,
        where: 'username = ? AND password = ?',
        whereArgs: [user, pass]);
    // list kết quả 0 rỗng
    if (maps.isNotEmpty) {
      _isLoggedIn = true; // Đăng nhập thành công
      _currentUsername = user; // Lưu tên user A hiện tại
      await _loadTasks(); // Tải danh sách Task của user A từ RAM
      notifyListeners();
      return true;
    }
    return false;
  }

  // Đăng xuất
  void logout() {
    _isLoggedIn = false;
    _currentUsername = "";
    _tasks = []; //clear danh sách Task trên RAM
    notifyListeners();
  }
  // đọc ổ cứng load vào RAM
  Future<void> _loadTasks() async {
    // DB truy vấn bảng taskTable với điều kiện username = _currentUsername
    final List<Map<String, dynamic>> maps = await _database!.query(taskTable, 
      where: 'username = ?', 
      whereArgs: [_currentUsername]
    );
    //danh sách mới = SL bản ghi tìm thấy trong DB, và các phần tử chuyển thành dữ liệu đọc đc hiện lên màn hình (Deserialize)
    _tasks = List.generate(maps.length, (i) => Task.fromMap(maps[i]));
    notifyListeners();
  }

  // Thêm Task : tốn thời gian ghi xuống DB
  Future<void> addTask(String title, String priority, DateTime date, String cat) async {
    final newTask = Task(
      id: DateTime.now().millisecondsSinceEpoch.toString(), //id duy nhất = thời gian hiện tại trên từng mili giây
      title: title,
      priority: priority,
      date: date,
      category: cat
    );
    //đóng gói dữ liệu thành cặp key - value để lưu vào DB (Serialize)
    Map<String, dynamic> data = newTask.toMap();
    data['username'] = _currentUsername; // kèm với chủ sở hữu

    await _database!.insert( taskTable, data, conflictAlgorithm: ConflictAlgorithm.replace,);// cơ chế phòng hờ lỗi trùng lặp ID
    _tasks.add(newTask);// new task vào bộ nhớ tạm RAM
    notifyListeners();
  }

  // Cập nhật trạng thái công việc
  Future<void> toggle(String id) async {// id là mã công việc
    final index = _tasks.indexWhere((t) => t.id == id); // tìm vị trí công việc trong danh sách RAM, nếu tìm thấy trả về index, ko thấy trả về -1
    if (index != -1) {
      _tasks[index].isCompleted = !_tasks[index].isCompleted;// đảo ngược trạng thái trên RAM True -> False, False -> True, DB chưa thay đổi
      Map<String, dynamic> data = _tasks[index].toMap(); // đóng gói dữ liệu Lưu xuống DB (key - value)
      data['username'] = _currentUsername;// ghi đè dữ liệu chủ sở hữu
      await _database!.update(taskTable, data, where: 'id = ?', whereArgs: [id]);
      notifyListeners();
    }
  }

  // Xóa Task ở 2 nơi: RAM và DB
  Future<void> delete(String id) async {
    await _database!.delete(taskTable, where: 'id = ?', whereArgs: [id]);//xoá cái công việc có id truyền vào
    _tasks.removeWhere((t) => t.id == id);// xoá trên RAM
    notifyListeners();
  }

  // Cập nhật Task: nhận nguyên 1 Task đã chỉnh sửa
  Future<void> updateTask(Task task) async {
    Map<String, dynamic> data = task.toMap(); // đóng gói dữ liệu Lưu xuống DB (key - value)
    data['username'] = _currentUsername; // Đảm bảo không mất chủ sở hữu
    await _database!.update(taskTable, data, where: 'id = ?', whereArgs: [task.id]);// cập nhật xuống DB
    final index = _tasks.indexWhere((t) => t.id == task.id);// tìm xem task cũ ở vị trí nào trên RAM
    if (index != -1) { _tasks[index] = task; notifyListeners(); }// tìm thấy vị trí cũ thì cháo hàng mới vào
  }
}