import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../features/auth/cubits/auth_cubit.dart';
import '../../../features/chat/screens/chat_screen.dart';
import '../../../services/api/chat_api_service.dart';
import '../../chat/cubits/chat_list_cubit.dart';

class ChatFAB extends StatelessWidget {
  const ChatFAB({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    
    if (!authState.isAuthenticated) {
      return const SizedBox.shrink();
    }

    return FloatingActionButton(
      onPressed: () => _handleChatPress(context),
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
    );
  }

  Future<void> _handleChatPress(BuildContext context) async {
    // Kiểm tra token trước khi mở chat
    await context.read<AuthCubit>().checkAuthStatus();

    if (!context.mounted) return;

    final authState = context.read<AuthCubit>().state;
    if (!authState.isAuthenticated || authState.accessToken == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Phiên đăng nhập đã hết hạn')),
      );
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
  }
}