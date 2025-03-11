import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_socket_io/services/api/chat_api_service.dart';
import '../../../data/models/story.dart';
import '../../../data/models/user.dart';
import '../../auth/cubits/auth_cubit.dart';
import '../widgets/stories_list.dart';
import '../widgets/messages_list.dart';
import '../cubits/chat_cubit.dart';
import '../cubits/chat_list_cubit.dart';
import 'chat_detail_screen.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({Key? key}) : super(key: key);

  Future<bool> _checkAuthAndGetToken(BuildContext context) async {
    final authCubit = context.read<AuthCubit>();
    await authCubit.checkAuthStatus();
    
    final state = authCubit.state;
    if (!state.isAuthenticated || state.accessToken == null || state.userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Phiên đăng nhập đã hết hạn')),
      );
      Navigator.pushReplacementNamed(context, '/');
      return false;
    }
    return true;
  }

  void _handleUserTap(BuildContext context, User selectedUser) async {
    if (!await _checkAuthAndGetToken(context)) return;

    final authCubit = context.read<AuthCubit>();
    final token = authCubit.state.accessToken;
    final currentUserId = authCubit.state.userId;

    // Double check to make TypeScript happy
    if (token == null || currentUserId == null) return;

    if (!context.mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (context) => ChatCubit(
            ChatApiService(
              token: token,
              currentUserId: currentUserId,
            ),
            selectedUser.id,
          ),
          child: ChatDetailScreen(
            username: selectedUser.fullName,
            userId: selectedUser.id,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: BlocBuilder<ChatListCubit, ChatListState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.error != null) {
            return Center(child: Text(state.error!));
          }

          final stories = state.users.map((user) => Story(
            username: user.fullName,
            avatarUrl: user.avatarUrl ?? "https://picsum.photos/200",
            lastMessage: user.email,
            timeAgo: "ONLINE",
            hasUnread: false,
          )).toList();

          return SafeArea(
            child: Column(
              children: [
                StoriesList(
                  stories: stories,
                  onStoryTap: (story) {
                    final selectedUser = state.users.firstWhere(
                      (user) => user.fullName == story.username
                    );
                    _handleUserTap(context, selectedUser);
                  },
                ),
                const Divider(height: 1),
                
                Expanded(
                  child: MessagesList(
                    stories: stories,
                    onMessageTap: (story) {
                      final selectedUser = state.users.firstWhere(
                        (user) => user.fullName == story.username
                      );
                      _handleUserTap(context, selectedUser);
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
} 