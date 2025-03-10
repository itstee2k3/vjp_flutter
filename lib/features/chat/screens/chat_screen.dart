import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_socket_io/services/api/chat_api_service.dart';
import '../models/story.dart';
import '../widgets/stories_list.dart';
import '../widgets/messages_list.dart';
import '../cubits/chat_cubit.dart';
import '../cubits/chat_list_cubit.dart';
import 'chat_detail_screen.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({Key? key}) : super(key: key);

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
                    
                    final chatService = context.read<ChatListCubit>().chatService;
                    print('ChatService currentUserId: ${chatService.currentUserId}'); // Debug log
                    
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BlocProvider(
                          create: (context) {
                            final chatService = context.read<ChatListCubit>().chatService;
                            return ChatCubit(chatService, selectedUser.id);
                          },
                          child: ChatDetailScreen(
                            username: selectedUser.fullName,
                            userId: selectedUser.id,
                          ),
                        ),
                      ),
                    );
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
                      
                      final chatService = context.read<ChatListCubit>().chatService;
                      print('ChatService currentUserId: ${chatService.currentUserId}'); // Debug log

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BlocProvider(
                            create: (context) {
                              final chatService = context.read<ChatListCubit>().chatService;
                              return ChatCubit(chatService, selectedUser.id);
                            },
                            child: ChatDetailScreen(
                              username: selectedUser.fullName,
                              userId: selectedUser.id,
                            ),
                          ),
                        ),
                      );
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