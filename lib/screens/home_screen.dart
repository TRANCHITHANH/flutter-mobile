import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../providers/todo_provider.dart';
import '../models/task_model.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime _selectedDay = DateTime.now();
  bool _showCompleted = false;
  @override
  void initState() {
    super.initState();
    // Gọi yêu cầu cấp quyền ngay khi khởi tạo màn hình
    _requestNotificationPermissions();
  }

  Future<void> _requestNotificationPermissions() async {
    final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    // Đối với Android
    final androidImplementation = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      // Hàm này sẽ kích hoạt hệ điều hành hiện hộp thoại Cho phép/Từ chối
      await androidImplementation.requestNotificationsPermission();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black, 
        primaryColor: const Color(0xFF7E84FF)
      ),
      child: Scaffold(
        floatingActionButton: FloatingActionButton(
          backgroundColor: const Color(0xFF7E84FF),
          shape: const CircleBorder(),
          elevation: 4,
          onPressed: () => _showForm(context, null), // Gọi form thêm mới (null)
          child: const Icon(Icons.add, color: Colors.white, size: 32),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,

        body: SafeArea(
          child: Column(children: [
            TableCalendar(
              firstDay: DateTime.utc(2023), lastDay: DateTime.utc(2030),
              focusedDay: _selectedDay, currentDay: _selectedDay,
              calendarFormat: CalendarFormat.month,
              headerStyle: const HeaderStyle(
                formatButtonVisible: false, titleCentered: true, 
                titleTextStyle: TextStyle(color: Colors.white, fontSize: 18)
              ),
              calendarStyle: const CalendarStyle(
                defaultTextStyle: TextStyle(color: Colors.white),
                selectedDecoration: BoxDecoration(color: Color(0xFF7E84FF), shape: BoxShape.rectangle, borderRadius: BorderRadius.all(Radius.circular(10))),
                todayDecoration: BoxDecoration(color: Colors.grey, shape: BoxShape.circle),
              ),
              onDaySelected: (s, f) => setState(() => _selectedDay = s),
            ),
            const SizedBox(height: 15),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              _tabBtn("Today", !_showCompleted, () => setState(() => _showCompleted = false)),
              const SizedBox(width: 15),
              _tabBtn("Completed", _showCompleted, () => setState(() => _showCompleted = true)),
            ]),
            const SizedBox(height: 15),
            Expanded(
              child: Consumer<TodoProvider>(builder: (ctx, prov, _) {
                final list = prov.tasks.where((t) => isSameDay(t.date, _selectedDay) && t.isCompleted == _showCompleted).toList();
                return list.isEmpty 
                  ? const Center(child: Text("Empty", style: TextStyle(color: Colors.grey))) 
                  : ListView.builder(
                      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 80),
                      itemCount: list.length,
                      itemBuilder: (_, i) => _taskItem(list[i], prov));
              }),
            )
          ]),
        ),
      ),
    );
  }

  Widget _tabBtn(String txt, bool active, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 30),
      decoration: BoxDecoration(color: active ? const Color(0xFF7E84FF) : Colors.transparent, borderRadius: BorderRadius.circular(10), border: active ? null : Border.all(color: Colors.grey)),
      child: Text(txt, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
    ),
  );

  Widget _taskItem(Task task, TodoProvider prov) => Dismissible(
    key: Key(task.id),
    onDismissed: (_) => prov.delete(task.id),
    background: Container(color: Colors.red, alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20), child: const Icon(Icons.delete)),
    child: Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF1F1F1F),
        borderRadius: BorderRadius.circular(15),

        //Thêm viền màu
        border: Border.all(
          color: _getPriorityColor(task.priority), // Gọi hàm lấy màu
          width: 1.5, // Độ dày của viền
        ),
        
      ),
      child: Row(children: [
        InkWell(
          onTap: () => prov.toggle(task.id), 
          child: Icon(
            task.isCompleted ? Icons.check_circle : Icons.circle_outlined, 
            // Nếu xong rồi thì màu tím, chưa xong thì lấy màu theo độ ưu tiên cho đồng bộ
            color: task.isCompleted ? const Color(0xFF7E84FF) : _getPriorityColor(task.priority)
          )
        ),
        const SizedBox(width: 15),
        Expanded(
          child: InkWell(
            onTap: () => _showForm(context, task),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(task.title, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, decoration: task.isCompleted ? TextDecoration.lineThrough : null)),
              Text(DateFormat('HH:mm').format(task.date), style: const TextStyle(color: Colors.grey, fontSize: 12))
            ]),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), 
          decoration: BoxDecoration(color: Colors.blue.withOpacity(0.2), borderRadius: BorderRadius.circular(5)), 
          child: Text(task.category, style: const TextStyle(color: Colors.blue, fontSize: 11, fontWeight: FontWeight.bold))
        )
      ]),
    ),
  );

  //Hàm show from chung add và edit 
  // Nếu task == null => Là Thêm mới  & >< != null => Là Sửa
  void _showForm(BuildContext ctx, Task? task) {
    final txt = TextEditingController(text: task?.title ?? "");
    String pri = task?.priority ?? 'Medium';
    String cat = task?.category ?? 'Work';
    TimeOfDay time = task != null ? TimeOfDay.fromDateTime(task.date) : TimeOfDay.now();

    showDialog(context: ctx, builder: (_) => StatefulBuilder(builder: (ctx, setS) => AlertDialog(
      backgroundColor: const Color(0xFF1F1F1F),
      title: Text(task == null ? "New Task" : "Edit Task", style: const TextStyle(color: Colors.white)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: txt, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(hintText: "Task Name", hintStyle: TextStyle(color: Colors.grey))),
        const SizedBox(height: 10),
        DropdownButton<String>(value: cat, dropdownColor: const Color(0xFF333333), items: ['Work', 'Sport'].map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(color: Colors.white)))).toList(), onChanged: (v) => setS(() => cat = v!)),
        const SizedBox(height: 10),
        DropdownButton<String>(value: pri, dropdownColor: const Color(0xFF333333), items: ['High', 'Medium', 'Low'].map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(color: Colors.white)))).toList(), onChanged: (v) => setS(() => pri = v!)),
        TextButton(onPressed: () async { final t = await showTimePicker(context: ctx, initialTime: time); if(t!=null) setS(()=> time=t); }, child: Text("Time: ${time.format(ctx)}"))
      ]),
      actions: [
        ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7E84FF)), onPressed: () {
          if (txt.text.isNotEmpty) {
            final provider = Provider.of<TodoProvider>(ctx, listen: false);
            final newDate = DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day, time.hour, time.minute);
            
            if (task == null) {
              provider.addTask(txt.text, pri, newDate, cat);
            } else {
              final updatedTask = Task(
                id: task.id, // Giữ nguyên ID
                title: txt.text,
                priority: pri,
                date: newDate,
                category: cat,
                isCompleted: task.isCompleted
              );
              provider.updateTask(updatedTask);
            }
            Navigator.pop(ctx);
          }
        }, child: Text(task == null ? "Add" : "Save", style: const TextStyle(color: Colors.white)))
      ],
    )));
  }
  // Hàm chọn màu dựa trên mức độ ưu tiên
  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'High':
        return Colors.redAccent; // Màu đỏ cho High
      case 'Medium':
        return Colors.orangeAccent; // Màu cam cho Medium
      case 'Low':
        return Colors.greenAccent; // Màu xanh cho Low
      default:
        return Colors.grey;
    }
  }
}