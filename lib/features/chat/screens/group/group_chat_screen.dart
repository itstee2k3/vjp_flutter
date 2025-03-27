import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubits/group/group_chat_cubit.dart';
import '../../cubits/group/group_chat_state.dart';
import '../../../../data/models/message.dart';
import '../../widgets/message_bubble.dart';
import '../../widgets/chat_input.dart';

class GroupChatScreen extends StatelessWidget {
  final int groupId;
  final String groupName;

  const GroupChatScreen({
    Key? key,
    required this.groupId,
    required this.groupName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(groupName),
      ),
      body: BlocBuilder<GroupChatCubit, GroupChatState>(
        builder: (context, state) {
          if (state.isTyping) {
            return const Center(child: Text('Someone is typing...'));
          }

          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.error != null) {
            return Center(child: Text(state.error!));
          }

          if (state.messages.isEmpty) {
            return const Center(child: Text('No messages yet'));
          }

          return ListView.builder(
            itemCount: state.messages.length,
            itemBuilder: (context, index) {
              final message = state.messages[index];
              final isMe = message.senderId == state.currentUserId;
              return MessageBubble(
                message: message,
                isMe: isMe,
              );
            },
          );
        },
      ),
      bottomNavigationBar: ChatInput(
        onSendMessage: (content) {
          context.read<GroupChatCubit>().sendMessage(content);
        },
        onTypingStarted: () {
          context.read<GroupChatCubit>().startTyping();
        },
        onTypingStopped: () {
          context.read<GroupChatCubit>().stopTyping();
        },
      ),
    );
  }
} 