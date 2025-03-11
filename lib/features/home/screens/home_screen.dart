// home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_socket_io/features/auth/cubits/auth_cubit.dart';
import 'package:flutter_socket_io/features/auth/cubits/auth_state.dart';
import 'package:flutter_socket_io/features/chat/screens/chat_screen.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../core/widgets/bottom_navbar.dart';
import '../../../core/widgets/top_navbar.dart';
import '../../../services/api/chat_api_service.dart';
import '../../chat/cubits/chat_list_cubit.dart';
import 'dart:convert';
import 'dart:convert' show base64Url;
import '../widgets/banner_widget.dart';
import '../widgets/search_widget.dart';
import '../widgets/company_vn_widget.dart';

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
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              // Top NavBar với hiệu ứng stretch
              const SliverAppBar(
                floating: false,
                pinned: true,
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                elevation: 0,
                expandedHeight: kToolbarHeight,
                flexibleSpace: FlexibleSpaceBar(
                  background: TopNavBar(),
                ),
                toolbarHeight: kToolbarHeight,
                leadingWidth: 0,
                automaticallyImplyLeading: false,
              ),

              // Banner có thể kéo giãn
              SliverToBoxAdapter(
                child: Container(
                  color: Colors.white,
                  child: const BannerWidget(),
                ),
              ),

              // Phần nội dung còn lại
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    // Thanh tìm kiếm
                    SearchWidget(
                      onSearch: (query) {
                        print('Searching for: $query');
                      },
                      onFlagChanged: (flag) {
                        print('Selected flag: $flag');
                      },
                    ),

                    // Phần nội dung chính
                    Column(
                      children: [
                        const SizedBox(height: 15),

                        Container(
                          width: double.infinity,
                          child: const FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              "NHỮNG CÔNG TY NỔI BẬT",
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                                letterSpacing: 1.2,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),

                        // CompanyVnWidget
                        const CompanyVnWidget(),
                      ],
                    ),
                  ],
                ),
              ),
            ],
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
                  Icons.chat_bubble_outline,
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
