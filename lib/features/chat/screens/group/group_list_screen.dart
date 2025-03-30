import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../data/models/group_chat.dart';
import '../../../../data/models/message.dart';
import '../../cubits/group/group_chat_list_cubit.dart';
import '../../cubits/group/group_chat_list_state.dart';
import '../../widgets/create_group_form.dart';

class GroupListScreen extends StatelessWidget {
  const GroupListScreen({Key? key}) : super(key: key);

  void _showCreateGroupDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const CreateGroupForm(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GroupChatListCubit, GroupChatListState>(
      builder: (context, state) {
        if (state.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.error != null) {
          return Center(child: Text(state.error!));
        }

        if (state.groups.isEmpty) {
          return const Center(
            child: Text('Chưa có nhóm chat nào'),
          );
        }

        return ListView.builder(
          itemCount: state.groups.length,
          itemBuilder: (context, index) {
            final group = state.groups[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundImage: group.avatarUrl != null && group.avatarUrl!.isNotEmpty
                    ? NetworkImage(group.avatarUrl!)
                    : AssetImage("assets/avatar_default/avatar_default.png") as ImageProvider,
              ),
              title: Text(
                group.name,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              subtitle: Text(
                _getMessagePreview(group.lastMessage),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontStyle: group.lastMessage == null ? FontStyle.italic : FontStyle.normal,
                ),
              ),
              trailing: group.lastMessage != null 
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _formatTime(group.lastMessageAt ?? DateTime.now()),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (group.lastMessage != null && !group.lastMessage!.isRead)
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
                context.push('/chat/group/${group.id}?groupName=${Uri.encodeComponent(group.name)}');
              },
            );
          },
        );
      },
    );
  }
  
  String _getMessagePreview(Message? message) {
    if (message == null) {
      return 'Chưa có tin nhắn';
    }
    
    switch (message.type) {
      case MessageType.text:
        return message.content;
      case MessageType.image:
        return '🖼️ Hình ảnh';
      case MessageType.file:
        return '📎 Tệp tin';
      case MessageType.audio:
        return '🎵 Âm thanh';
      case MessageType.video:
        return '🎬 Video';
      default:
        return message.content;
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