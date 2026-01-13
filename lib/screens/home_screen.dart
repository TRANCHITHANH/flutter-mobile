import 'package:flutter/material.dart';
import 'package:intl/intl.dart';//format ngày giờ: DateFormat('HH:mm').format(dateTime)--> 16:01
import 'package:provider/provider.dart'; //Dùng để nghe và cập nhật dữ liệu từ Provider
import 'package:table_calendar/table_calendar.dart'; //Thư viện hiển thị lịch
import '../providers/todo_provider.dart';//Quản lý dữ liệu (task, user), kết nối giữa UI và logic nghiệp vụ
import '../models/task_model.dart';//File định nghĩa cấu trúc dữ liệu của một Task

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {//widget có trạng thái thay đổi
  DateTime _selectedDay = DateTime.now();// Biến lưu ngày người dùng đang chọn trên lịch.
  bool _showCompleted = false;// Biến điều khiển Tab: false (Việc cần làm), true (Việc đã xong).

  @override
  Widget build(BuildContext context) {// xây dựng giao diện
    return Theme(
      data: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black, // Nền tối
        primaryColor: const Color(0xFF7E84FF) // màu tím chủ đạo
      ),
      child: Scaffold(//khung màn hình bố cục giao diện
        floatingActionButton: FloatingActionButton(// nút hành động nổi: thêm mới công việc
          backgroundColor: const Color(0xFF7E84FF),// màu tím
          shape: const CircleBorder(),// hình tròn
          elevation: 4, //độ nổi bóng 
          onPressed: () => _showForm(context, null), // sự kiện khi bấm nút: hiển thị form thêm mới công việc
          child: const Icon(Icons.add, color: Colors.white, size: 32), // hiển thị icon dấu cộng, màu trắng, kích thước 32px
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat, // vị trí nút hành động nổi: góc dưới bên phải

        body: SafeArea(//tự động chừa khoảng trống để nội dung ko bị che
          child: Column(children: [//sắp xếp các widget con theo cột dọc: Header, Calendar, Tabs, Task List
            Padding(
              padding: const EdgeInsets.all(15),//Tạo khoảng cách 15px xung quanh nội dung bên trong
              child: Row(// bố cục ngang
                mainAxisAlignment: MainAxisAlignment.spaceBetween,// căn đều 2 bên
                children: [ //row gồm 2 thành phần: Tên người dùng & nút Logout
                  // Hiển thị tên người dùng lấy từ Provider
                  Consumer<TodoProvider>(builder: (_, prov, __) => Text(
                    "Hi, ${prov.currentUsername}", 
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)// chữ màu trắng, cỡ 18, in đậm
                  )),
                  
                  IconButton(
                    icon: const Icon(Icons.logout, color: Colors.redAccent),
                    onPressed: () {
                       // Gọi hàm logout, Provider sẽ báo main.dart chuyển về màn hình Login
                       Provider.of<TodoProvider>(context, listen: false).logout();
                    },
                  )
                ],
              ),
            ),

            TableCalendar(// widget hiển thị lịch
              firstDay: DateTime.utc(2023), lastDay: DateTime.utc(2030),// khoảng ngày hiển thị từ 2023 đến 2030, dùng DateTime.utc để tránh lỗi múi giờ
              focusedDay: _selectedDay, currentDay: _selectedDay,//_selectedDay là ngày được chọn và cũng là ngày hiện tại
              calendarFormat: CalendarFormat.month,// định dạng hiển thị theo tháng
              headerStyle: const HeaderStyle(//header của lịch
                formatButtonVisible: false, titleCentered: true, // ẩn nút Month/Week, căn giữa tiêu đề
                titleTextStyle: TextStyle(color: Colors.white, fontSize: 18)
              ),

              calendarStyle: const CalendarStyle(// style của lịch
                defaultTextStyle: TextStyle(color: Colors.white),// ngày thường màu trắng suốt
                //ngày đc chọn: nền tím, bo góc vuông tròn nhẹ
                selectedDecoration: BoxDecoration(color: Color(0xFF7E84FF), shape: BoxShape.rectangle, borderRadius: BorderRadius.all(Radius.circular(10))),
                //hôm nay: nền xám, hình tròn
                todayDecoration: BoxDecoration(color: Colors.grey, shape: BoxShape.circle),
              ),
              onDaySelected: (s, f) => setState(() => _selectedDay = s),// sự kiện khi người dùng chọn ngày trên lịch: cập nhật _selectedDay và làm mới UI
            ),
            const SizedBox(height: 15),

            //2 nút 1 biến state
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [// căn giữa 2 nút tab
              _tabBtn("Today", !_showCompleted, () => setState(() => _showCompleted = false)),// nếu: _showCompleted == false --> tab Today hoạt động
              const SizedBox(width: 15),
              _tabBtn("Completed", _showCompleted, () => setState(() => _showCompleted = true)),// ngược lại
            ]),
            const SizedBox(height: 15),
            
            Expanded(//witget này chiếm toàn bộ không gian còn lại, ListView cuộn mượt hơn
            // Consumer kết nối trực tiếp TodoProvider, khi nào Provider gọi lệnh notifyListeners (CRUD Task, toggle, v.v.) --> Consumer nhận tín hiệu và làm mới UI bên trong nó (chạy builder)
              child: Consumer<TodoProvider>(builder: (ctx, prov, _) {
              //lọc 2 điều kiện: 
              //prov.tasks: danh sách tất cả công việc của người dùng hiện tại
              //đúng ngày đang chọn trên lịch & đúng trạng thái hoàn thành/chưa hoàn thành
                final list = prov.tasks.where((t) => isSameDay(t.date, _selectedDay) && t.isCompleted == _showCompleted).toList();
                //.toList(): Gom những việc thỏa mãn điều kiện lại thành một danh sách mới để chuẩn bị hiển thị.
                return list.isEmpty // xử lý khi danh sách rỗng
                  ? const Center(child: Text("Empty", style: TextStyle(color: Colors.grey))) // nếu rỗng hiển thị chữ "Empty" màu xám ở giữa
                  : ListView.builder(//nếu có dữ liệu thì hiển thị danh sách công việc: 5 - 6 dòng 1 lúc, cuộn mượt, tránh tập thể -> lag màn hình
                      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 80),// Căn lề cho đẹp, tránh bị che bởi nút ở góc
                      itemCount: list.length, // Báo cho máy biết danh sách có bao nhiêu dòng (để chuẩn bị thanh cuộn)
                      itemBuilder: (_, i) => _taskItem(list[i], prov));//vẽ từng dòng (tiêu đề, màu sắc, checkbox, v.v.), nó lấy công việc thứ i của List[i] để hiển thị
              }),
            )
          ]),
        ),
      ),
    );
  }

  // Widget nút chuyển tab (today / completed)
  // chữ hiển thị trên nút, trạng thái hoạt động(sáng đèn - tối đèn), sự kiện khi bấm
  Widget _tabBtn(String txt, bool active, VoidCallback onTap) => GestureDetector( // bộ cảm biến ấn nút chạy hàm dưới, GestureDetector: vô hình
    onTap: onTap,
    child: Container(// vô hình -> hình dạng hiển thị nút bt phản hồi
      //nó đẩy chữ text cách lề trên & dưới 10 px, cách lề trái & phải 30 px
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 30),
      //1: xử lý màu viền: active T: tô tím, F: nền trong suốt
      //2: bo tròn góc
      //3: xử lý viền, active F: thấy khung viền xám
      decoration: BoxDecoration(color: active ? const Color(0xFF7E84FF) : Colors.transparent, borderRadius: BorderRadius.circular(10), border: active ? null : Border.all(color: Colors.grey)),
      //đặt dòng chữ vào giữa ô, chữ luôn màu trắng, in đậm
      child: Text(txt, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
    ),
  );

  Widget _taskItem(Task task, TodoProvider prov) => Dismissible(//Dismissible: cơ chế vuốt để xoá
    key: Key(task.id),//key định danh công việc
    onDismissed: (_) => prov.delete(task.id),// khi vuốt hết hành trình hàm onDismissed như kèo súng gọi hàm prov.delete xoá viễn viễn dữ liệu DB & RAM
    //hình ảnh chìm dưới thẻ khi kéo sang mới thấy nền đỏ dưới --> báo hiệu kéo sang sử dụng xóa
    background: Container(color: Colors.red, alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20), child: const Icon(Icons.delete)),
    //giao diện hiển thị
    child: Container(
      margin: const EdgeInsets.only(bottom: 15), // Tạo khoảng cách giữa các thẻ
      padding: const EdgeInsets.all(15), // Tạo độ thoáng bên trong thẻ
      decoration: BoxDecoration(
        color: const Color(0xFF1F1F1F), // nền đen
        borderRadius: BorderRadius.circular(15), // bo góc

        //Thêm viền màu
        border: Border.all(
          color: _getPriorityColor(task.priority), // Gọi hàm lấy màu viền theo độ ưu tiên
          width: 1.5, // Độ dày của viền
        ),
        
      ),
      //sắp xếp nội dung bên trong thẻ: nút check, tiêu đề, nhãn ưu tiên
      child: Row(children: [// bố trí theo chiều ngang
        InkWell(// biến cái icon vô tri thành nút bấm đc, khi ấn vào thì gọi hàm thay đổi trạng thái toggle(xong rồi chưa xong)
          onTap: () => prov.toggle(task.id), 
          child: Icon(
            //toán tử 3 ngôi: Nếu xong (true) thì hiện hình tròn đặc có dấu tích (check_circle). Nếu chưa (false) thì hiện vòng tròn rỗng (circle_outlined).
            // Nếu xong rồi thì màu tím, chưa xong thì lấy màu theo độ ưu tiên cho đồng bộ
            task.isCompleted ? Icons.check_circle : Icons.circle_outlined, 
            color: task.isCompleted ? const Color(0xFF7E84FF) : _getPriorityColor(task.priority)
          )
        ),
        const SizedBox(width: 15), // các icon & chữ : 15px
        Expanded(//Expanded ra lệnh tiêu đề quá dài thì có thể xuống dòng, nhãn Category dính sát vào lề phải.
          child: InkWell(//khi bấm vào đây mở form sửa task
            onTap: () => _showForm(context, task),
            //sắp xếp dọc: tên công việc ở trên và time ở dưới
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              //decoration: ... lineThrough: Nếu xong rồi thì gạch ngang chữ đi (tạo cảm giác hoàn thành).
              Text(task.title, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, decoration: task.isCompleted ? TextDecoration.lineThrough : null)),
              //Text(DateFormat...): Dùng thư viện intl để định dạng giờ (ví dụ "14:30"). Chữ 12 màu xám.
              Text(DateFormat('HH:mm').format(task.date), style: const TextStyle(color: Colors.grey, fontSize: 12))
            ]),
          ),
        ),
        //nhãn danh mục
        Container(
          //nó đẩy chữ text cách lề trên & dưới 4 px, cách lề trái & phải 8 px
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), 
          decoration: BoxDecoration(color: Colors.blue.withOpacity(0.2), borderRadius: BorderRadius.circular(5)), // nền xanh ,bo góc 
          child: Text(task.category, style: const TextStyle(color: Colors.blue, fontSize: 11, fontWeight: FontWeight.bold)) // thiết kế chữ: xanh, 11px, in đậm
        )
      ]),
    ),
  );

  //Hàm show from chung add và edit (đa năng 2 trong 1 hàm)
  //Hàm _showForm này chịu trách nhiệm hiển thị một cái hộp thoại (Dialog) để nhập liệu: 
  // Nếu task == null => Là Thêm mới  & >< != null => Là Sửa (Tạo mới (Add): Nếu không truyền task vào >< Chỉnh sửa (Edit): Nếu có truyền task vào.)
  void _showForm(BuildContext ctx, Task? task) { // task? nghĩa là có thể có hoặc có thể null

    // * Toán tử ??: Có nghĩa là "Nếu cái đằng trước bị null thì lấy cái đằng sau".
    // 1. Ô nhập tên: Nếu là sửa (task có dữ liệu) thì điền tên cũ vào. Nếu là mới (task null) thì để rỗng ("").
    final txt = TextEditingController(text: task?.title ?? "");
    // 2. Độ ưu tiên: Nếu sửa thì lấy cái cũ, nếu mới thì mặc định là 'Medium','Work'
    String pri = task?.priority ?? 'Medium';
    String cat = task?.category ?? 'Work';
    // 3. Giờ giấc: Nếu sửa thì lấy giờ của task đó, nếu mới thì lấy giờ hiện tại (TimeOfDay.now()).
    TimeOfDay time = task != null ? TimeOfDay.fromDateTime(task.date) : TimeOfDay.now();

    //Dựng khung Dialog & Xử lý trạng thái cục bộ:
    //showDialog: Lệnh trong Flutter để hiện popup đè lên màn hình.
    //StatefulBuilder cung cấp một hàm setS (giống setState) nhưng chỉ dành riêng cho cái Dialog này. 
    //Khi dùng setS, chỉ cái Dialog được vẽ lại, màn hình chính bên dưới giữ nguyên.
    showDialog(context: ctx, builder: (_) => StatefulBuilder(builder: (ctx, setS) => AlertDialog(
      backgroundColor: const Color(0xFF1F1F1F),// nền đen
      // Tiêu đề đổi linh hoạt: "New Task" hoặc "Edit Task" tùy vào đang làm gì
      title: Text(task == null ? "New Task" : "Edit Task", style: const TextStyle(color: Colors.white)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        //ô nhập tên task
        TextField(controller: txt, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(hintText: "Task Name", hintStyle: TextStyle(color: Colors.grey))),
        const SizedBox(height: 10),
        //Dropdown chọn Danh mục (Work/Sport),                            Khi chọn cái mới -> gọi setS để vẽ lại Dropdown ngay lập tức
        DropdownButton<String>(value: cat, dropdownColor: const Color(0xFF333333), items: ['Work', 'Sport'].map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(color: Colors.white)))).toList(), onChanged: (v) => setS(() => cat = v!)),
        const SizedBox(height: 10),
        //Dropdown chọn Độ ưu tiên (High/Medium/Low),                   Khi chọn cái mới -> gọi setS để vẽ lại Dropdown ngay lập tức
        DropdownButton<String>(value: pri, dropdownColor: const Color(0xFF333333), items: ['High', 'Medium', 'Low'].map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(color: Colors.white)))).toList(), onChanged: (v) => setS(() => pri = v!)),
        // nút chọn time
        TextButton(onPressed: () async { 
          // Hiện cái đồng hồ xoay xoay để chọn giờ
          final t = await showTimePicker(context: ctx, initialTime: time);
          // Nếu người dùng chọn xong (khác null) -> Cập nhật biến time và vẽ lại nút
          if(t!=null) setS(()=> time=t); }, 
          child: Text("Time: ${time.format(ctx)}"))// Hiện giờ đã chọn lên nút
      ]),
      // Nút lặp: "Add" hoặc "Save" tùy vào đang làm gì
      actions: [
        ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7E84FF)), onPressed: () {
          // Kiểm tra: Không được để tên trống
          if (txt.text.isNotEmpty) {
            // Gọi ông quản lý kho (Provider) ra
            final provider = Provider.of<TodoProvider>(ctx, listen: false);
            // ghép ngày đang chọn ở màn hình và giờ vừa chọn trong dialog
            final newDate = DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day, time.hour, time.minute);
            //TH1: tạo mới, quăng dữ liệu vào , Provider tự sinh ID
            if (task == null) {
              provider.addTask(txt.text, pri, newDate, cat);
            } else {// TH2: sửa task
              final updatedTask = Task(
                id: task.id, // tạo 1 đối tượng task mới nhưng giữ nguyên ID
                title: txt.text,
                priority: pri,
                date: newDate,
                category: cat,
                isCompleted: task.isCompleted
              );
              provider.updateTask(updatedTask);
            }
            Navigator.pop(ctx);// Đóng Dialog lại
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