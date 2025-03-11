// home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_socket_io/features/auth/cubits/auth_cubit.dart';
import 'package:flutter_socket_io/features/auth/cubits/auth_state.dart';
import 'package:flutter_socket_io/features/chat/screens/chat_screen.dart';
import '../../../core/widgets/bottom_navbar.dart';
import '../../../core/widgets/top_navbar.dart';
import '../../../services/api/chat_api_service.dart';
import '../../chat/cubits/chat_list_cubit.dart';
import 'dart:convert';
import 'dart:convert' show base64Url;

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String selectedFlag = 'vn'; // Default là cờ Việt Nam

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        return Scaffold(
          appBar: const TopNavBar(),
          body: SingleChildScrollView(
            child: Column(
              children: [
                // Banner image
                Image.network(
                  'https://vjp-connect.com/_next/static/media/vjp-connect-banner-sm.eed45626.webp',
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),

                // Thanh tìm kiếm
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Column(
                    children: [
                      // Ô tìm kiếm
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const TextField(
                          decoration: InputDecoration(
                            hintText: 'Tìm kiếm doanh nghiệp...',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 15),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 15),
                      
                      // Row chứa cờ và nút tìm kiếm
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Cờ Việt Nam
                          GestureDetector(
                            onTap: () => setState(() => selectedFlag = 'vn'),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: selectedFlag == 'vn' 
                                      ? Colors.blue 
                                      : Colors.grey.shade300,
                                  width: selectedFlag == 'vn' ? 2 : 1,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Image.network(
                                'https://vjp-connect.com/images/logo2.png',
                                width: 24,
                                height: 24,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          
                          // Cờ Nhật
                          GestureDetector(
                            onTap: () => setState(() => selectedFlag = 'jp'),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: selectedFlag == 'jp' 
                                      ? Colors.blue 
                                      : Colors.grey.shade300,
                                  width: selectedFlag == 'jp' ? 2 : 1,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Image.network(
                                'https://vjp-connect.com/images/logo4.png',
                                width: 24,
                                height: 24,
                              ),
                            ),
                          ),
                          const SizedBox(width: 20),
                          
                          // Nút tìm kiếm
                          ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 15,
                              ),
                            ),
                            child: const Text(
                              'Tìm doanh nghiệp',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Phần nội dung chính
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      // Tiêu đề chính
                      Container(
                        width: double.infinity,
                        child: const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            "NHỮNG CÔNG TY NỔI BẬT",
                            style: TextStyle(
                              fontSize: 28, // Kích thước tối đa
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                              letterSpacing: 1.2,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Tiêu đề phụ với gạch ngang
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 60,
                              height: 1,
                              color: Colors.blue,
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              child: RichText(
                                text: const TextSpan(
                                  children: [
                                    TextSpan(
                                      text: "CÔNG TY ",
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.blue,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    TextSpan(
                                      text: "VIỆT NAM",
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.red,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Container(
                              width: 60,
                              height: 1,
                              color: Colors.blue,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),

                      // Grid công ty nổi bật
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 1.2,
                          crossAxisSpacing: 20,
                          mainAxisSpacing: 20,
                        ),
                        itemCount: 6,
                        itemBuilder: (context, index) {
                          return Card(
                            elevation: 4,
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      children: const [
                                        Padding(
                                          padding: EdgeInsets.only(right: 4),
                                          child: Chip(label: Text("JCI")),
                                        ),
                                        Padding(
                                          padding: EdgeInsets.only(right: 4),
                                          child: Chip(label: Text("BNI")),
                                        ),
                                        Padding(
                                          padding: EdgeInsets.only(right: 4),
                                          child: Chip(label: Text("VJCN")),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Flexible(
                                    child: Text(
                                      "Công ty ${index + 1}",
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: const BottomNavBar(),
          floatingActionButton: state.isAuthenticated 
            ? FloatingActionButton(
                onPressed: () async {
                  // Kiểm tra token trước khi mở chat
                  await context.read<AuthCubit>().checkAuthStatus();
                  
                  final authState = context.read<AuthCubit>().state;
                  if (!authState.isAuthenticated || authState.accessToken == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Phiên đăng nhập đã hết hạn')),
                    );
                    Navigator.pushReplacementNamed(context, '/');
                    return;
                  }

                  // Tạo ChatListCubit với token mới nhất
                  final chatListCubit = ChatListCubit(
                    ChatApiService(
                      token: authState.accessToken,
                      currentUserId: authState.userId,
                    ),
                    authCubit: context.read<AuthCubit>(),
                  );

                  // Load users trước khi navigate
                  await chatListCubit.loadUsers();
                  
                  if (!context.mounted) return;

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BlocProvider.value(
                        value: chatListCubit,
                        child: const ChatScreen(),
                      ),
                    ),
                  );
                },
                backgroundColor: Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                  side: const BorderSide(
                    color: Colors.black12,
                    width: 0.5,
                  ),
                ),
                child: const Icon(
                  Icons.mark_unread_chat_alt_outlined,
                  color: Colors.black87,
                  size: 26,
                ),
              )
            : null,
        );
      },
    );
  }
}
