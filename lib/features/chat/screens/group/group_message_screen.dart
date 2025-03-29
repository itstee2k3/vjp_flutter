import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../data/models/group_chat.dart';
import '../../../../data/models/message.dart';
import '../../../../data/models/user.dart';
import '../../../../services/api/group_chat_api_service.dart';
import '../../cubits/group/group_chat_cubit.dart';
import '../../cubits/group/group_chat_state.dart';
import '../../widgets/chat_input_field.dart';
import '../../widgets/message_list.dart';

class GroupMessageScreen extends StatefulWidget {
  final String groupName;
  final int groupId;

  const GroupMessageScreen({
    Key? key,
    required this.groupName,
    required this.groupId,
  }) : super(key: key);

  @override
  State<GroupMessageScreen> createState() => _GroupMessageScreenState();
}

class _GroupMessageScreenState extends State<GroupMessageScreen> with WidgetsBindingObserver {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Map<String, User> _userCache = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadMessages();
    _loadUserAvatars();
  }

  Future<void> _loadUserAvatars() async {
    try {
      final cubit = context.read<GroupChatCubit>();
      final members = await cubit.apiService.getGroupMembers(widget.groupId);
      for (var member in members) {
        final user = User.fromJson(member);
        _userCache[user.id] = user;
      }
      setState(() {});
    } catch (e) {
      print('Error loading user avatars: $e');
    }
  }

  Future<void> _loadMessages() async {
    try {
      setState(() => _isLoading = true);
      await context.read<GroupChatCubit>().loadMessages();
    } catch (e) {
      print('Error loading messages: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi tải tin nhắn: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _handleSendMessage(String content) {
    if (content.trim().isEmpty) return;
    context.read<GroupChatCubit>().sendMessage(content);
    _messageController.clear();
  }

  Future<void> _handleSendImage() async {
    try {
      setState(() => _isLoading = true);
      // TODO: Implement image sending for group chat
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tính năng gửi ảnh đang được phát triển')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi gửi ảnh: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.groupName),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              _loadMessages();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Đang tải lại tin nhắn...')),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.info_outline),
            onPressed: () {
              // Navigate to group info screen
            },
          ),
        ],
      ),
      body: BlocListener<GroupChatCubit, GroupChatState>(
        listener: (context, state) {
          if (state.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.error!)),
            );
          }
        },
        child: Column(
          children: [
            Expanded(
              child: BlocBuilder<GroupChatCubit, GroupChatState>(
                builder: (context, state) {
                  if (state.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state.messages.isEmpty) {
                    return const Center(child: Text('Chưa có tin nhắn nào'));
                  }

                  return MessageList(
                    messages: state.messages,
                    currentUserId: context.read<GroupChatCubit>().apiService.currentUserId ?? '',
                    scrollController: _scrollController,
                    onRetryImage: () {
                      // TODO: Implement retry image for group chat
                    },
                  );
                },
              ),
            ),
            ChatInputField(
              controller: _messageController,
              onSend: () => _handleSendMessage(_messageController.text),
              onImageSend: _handleSendImage,
              isLoading: _isLoading,
            ),
          ],
        ),
      ),
    );
  }
}