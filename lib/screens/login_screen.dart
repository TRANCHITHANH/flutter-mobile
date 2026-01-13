import 'package:flutter/material.dart';
import 'package:provider/provider.dart';// quản lý dữ liệu (task, user), kết nối giữa UI và logic nghiệp vụ
import '../providers/todo_provider.dart';

class LoginScreen extends StatefulWidget {// widget đăng nhập có state thay đổi khi người dùng nhập dữ liệu
  //ko thay đổi cấu trúc nên dùng const 
  //key: định danh widget trong cây widget (so sánh widget mới - cũ) --> chuyền key lên lớp cha
  const LoginScreen({super.key});

  @override
  //ghi đè: yêu cầu StatefulWidget tạo ra State tương ứng
  //Method createState: trả về đối tượng quản lý trạng thái
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  //lấy dữ liệu người dùng nhập trong TextField
  final _userController = TextEditingController();
  final _passController = TextEditingController();

  @override
  Widget build(BuildContext context) {// xây dựng giao diện: cung cấp tt vị trí của widget trong cây UI: dùng gọi Provider, ScanffoldMessenger, Navigator
    return Scaffold(// khung màn hình chứa bố cục
      backgroundColor: Colors.black,// nền tối

      body: Padding(
        padding: const EdgeInsets.all(20), //cách viền cách đều 20px
        child: Column( //sắp xếp theo cột dọc
          mainAxisAlignment: MainAxisAlignment.center, // canh giữa theo trục chính (dọc)

          children: [
            const Icon(Icons.lock_outline, size: 80, color: Color(0xFF7E84FF)), // icon ô khóa
            const SizedBox(height: 20), //tạo 1 hộp có kích thước cố định

            const Text("Vui lòng đăng nhập", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),//tiêu đề màn hình
            const SizedBox(height: 40),
            
            TextField(//gắn textfield với controller khi người dùng nhâp: _userController.text thay đổi
              controller: _userController,
              style: const TextStyle(color: Colors.white),// chữ nhập màu trắng
              decoration: InputDecoration(
                hintText: "Username", hintStyle: const TextStyle(color: Colors.grey),// chữ gợi ý màu xám
                filled: true, fillColor: const Color(0xFF1F1F1F), // nền ô nhập
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none) //bo góc 10px, ko viền
              ),
            ),
            const SizedBox(height: 15),

            TextField(
              controller: _passController,
              obscureText: true, // Ẩn mật khẩu
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Password", hintStyle: const TextStyle(color: Colors.grey),
                filled: true, fillColor: const Color(0xFF1F1F1F),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none)
              ),
            ),
            const SizedBox(height: 30),
            
            // Nút Đăng Nhập
            SizedBox(// đặt kích thước cố định cho nút
              width: double.infinity,// nút rộng hết khung ngang
              height: 50, // cao 50px
              child: ElevatedButton(// nút bấm nổi, có hiệu ứng đổ bóng
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7E84FF)),// màu nền nút
                onPressed: () async {// khi user bấm nút đăng nhập
                  final provider = Provider.of<TodoProvider>(context, listen: false);// lấy đối tượng TodoProvider từ cây widget ra dùng(gọi hàm và ko update UI)
                  bool success = await provider.login(_userController.text, _passController.text); // lấy dữ liệu từ 2 ô nhập gửi cho hàm login --> chờ kết quả T,F
                  if (!success) {// nếu đăng nhập thất bại
                  // hiển thị thông báo ở dưới cùng màn hình
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Sai tài khoản hoặc mật khẩu!")));
                  }
                },
                //tạo widget chữ trong nút, trang trí chữ màu trắng, in đậm
                child: const Text("LOGIN", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 10),
            
            // Nút Đăng Ký
            TextButton(// nút bấm dạng chữ
              onPressed: () async {
                final provider = Provider.of<TodoProvider>(context, listen: false);
                if (_userController.text.isEmpty || _passController.text.isEmpty) { // nếu 1 trong 2 ô trống
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Vui lòng nhập đầy đủ!")));
                   return;//dừng lại ko chạy tiếp
                }
                bool success = await provider.register(_userController.text, _passController.text);
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đăng ký thành công! Hãy đăng nhập.")));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Tài khoản đã tồn tại!")));
                }
              },
              child: const Text("Create new account", style: TextStyle(color: Colors.grey)),
            )
          ],
        ),
      ),
    );
  }
}