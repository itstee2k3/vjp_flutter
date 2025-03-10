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

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        return Scaffold(
          appBar: const TopNavBar(),
          body: const Center(child: Text("Chào mừng đến với ứng dụng!")),
          bottomNavigationBar: const BottomNavBar(),
          floatingActionButton: state.isAuthenticated ? FloatingActionButton(
            onPressed: () {
              final token = state.accessToken;
              // Decode JWT để lấy sub (userId)
              final parts = token!.split('.');
              final payload = parts[1];
              final normalized = base64Url.normalize(payload);
              final payloadMap = jsonDecode(utf8.decode(base64Url.decode(normalized)));
              final currentUserId = payloadMap['sub'];

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BlocProvider(
                    create: (context) {
                      final authCubit = context.read<AuthCubit>();
                      return ChatListCubit(
                        ChatApiService(
                          token: token,
                          currentUserId: currentUserId,
                        ),
                        authCubit: authCubit,
                      )..loadUsers();
                    },
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
          ) : null,
        );
      },
    );
  }
}
