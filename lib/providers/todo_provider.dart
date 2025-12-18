import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/task_model.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;

//Class TodoProvider như Controller đứng giữa Model (Task) và View (Giao diện) --> quản lý trạng thái và thao tác với dữ liệu
// Biến Class này thành 1 trạm sóng, khi nó kế thừa có khả năng dùng loa notifyListeners(): hét cho toàn bộ ứng dụng mỗi khi dữ liệu thay đổi    XXX đơ, update new task
class TodoProvider extends ChangeNotifier {
  // Biến lưu trữ kết nối đến database SQLite: lúc mở app DB chưa kịp load nên để biến này là null được (?), sau khi hàm init() chạy xong thì nó sẽ có giá trị, _: private
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
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
    tz.initializeTimeZones();

    // 2. Khởi tạo Notification
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings = InitializationSettings(android: androidSettings);
    await _notificationsPlugin.initialize(initSettings);
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
  Future<void> _scheduleNotification(Task task) async {
    // Không báo thức nếu task đã xong hoặc thời gian ở quá khứ
    if (task.isCompleted || task.date.isBefore(DateTime.now())) return;

    await _notificationsPlugin.zonedSchedule(
      task.id.hashCode, // ID duy nhất cho thông báo (int)
      'Nhắc nhở công việc',
      task.title,
      tz.TZDateTime.from(task.date, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'alarm_channel',
          'Báo thức công việc',
          importance: Importance.max,
          priority: Priority.high,
          sound: const RawResourceAndroidNotificationSound('notification_sound'),
          enableVibration: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
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
    await _scheduleNotification(newTask);
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
    await _notificationsPlugin.cancel(id.hashCode);
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