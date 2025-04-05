import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../data/models/user.dart';
import '../../../../data/models/message.dart';
import '../../cubits/personal/personal_chat_list_cubit.dart';
import '../../../../features/auth/cubits/auth_cubit.dart';

class PersonalListScreen extends StatelessWidget {
  const PersonalListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.read<AuthCubit>().state.userId;
    
    return BlocBuilder<PersonalChatListCubit, PersonalChatListState>(
      builder: (context, state) {
        if (state.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.error != null) {
          return Center(child: Text(state.error!));
        }

        return ListView.builder(
          itemCount: state.users.length,
          itemBuilder: (context, index) {
            final user = state.users[index];
            final latestMessage = state.latestMessages[user.id];
            
            return ListTile(
              leading: CircleAvatar(
                backgroundImage: user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                    ? NetworkImage(user.avatarUrl!)
                    : AssetImage("assets/avatar_default/avatar_default.png") as ImageProvider,
              ),
              title: Text(
                user.fullName,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              subtitle: Text(
                _getMessagePreview(latestMessage, currentUserId),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontStyle: latestMessage == null ? FontStyle.italic : FontStyle.normal,
                ),
              ),
              trailing: latestMessage != null 
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _formatTime(latestMessage.sentAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (!latestMessage.isRead && latestMessage.receiverId == currentUserId)
                        Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  )
                : null,
              onTap: () {
                context.push('/chat/personal/${user.id}?username=${Uri.encodeComponent(user.fullName)}');
              },
            );
          },
        );
      },
    );
  }
  
  String _getMessagePreview(Message? message, String? currentUserId) {
    if (message == null) {
      return 'Chưa có tin nhắn';
    }
    
    String prefix = '';
    if (message.senderId == currentUserId) {
      prefix = 'Bạn: ';
    }
    
    switch (message.type) {
      case MessageType.text:
        return '$prefix${message.content}';
      case MessageType.image:
        return '$prefix🖼️ Hình ảnh';
      case MessageType.file:
        return '$prefix📎 Tệp tin';
      case MessageType.audio:
        return '$prefix🎵 Âm thanh';
      case MessageType.video:
        return '$prefix🎬 Video';
      default:
        return '$prefix${message.content}';
    }
  }
  
  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(time.year, time.month, time.day);
    
    if (messageDate == today) {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } else if (messageDate == yesterday) {
      return 'Hôm qua';
    } else if (now.difference(time).inDays < 7) {
      return ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'][time.weekday - 1];
    } else {
      return '${time.day}/${time.month}/${time.year}';
    }
  }
} 