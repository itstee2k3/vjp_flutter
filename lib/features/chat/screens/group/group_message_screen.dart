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
import '../../widgets/chat_header.dart';

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

class _GroupMessageScreenState extends State<GroupMessageScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Map<String, User> _userCache = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _loadUserAvatars();
    _setupMessageStream();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _setupMessageStream() {
    final chatCubit = context.read<GroupChatCubit>();
    chatCubit.stream.listen((state) {
      if (state.messages.isNotEmpty && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });
      }
    });
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

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    final content = _messageController.text.trim();
    _messageController.clear();

    try {
      context.read<GroupChatCubit>().sendMessage(content);
      _scrollToBottom();
    } catch (e) {
      print('Error sending message: $e');
    }
  }

  Future<void> _sendImage() async {
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
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: ChatHeader(
          title: widget.groupName,
          isGroup: true,
          onRefreshPressed: () {
            context.read<GroupChatCubit>().resetAndReloadMessages();
          },
          onInfoPressed: () {
            // TODO: Navigate to group info screen
          },
        ),
      ),
      body: BlocBuilder<GroupChatCubit, GroupChatState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              Expanded(
                child: MessageList(
                  messages: state.messages,
                  currentUserId: context.read<GroupChatCubit>().apiService.currentUserId ?? '',
                  scrollController: _scrollController,
                  onRetryImage: () {
                    // TODO: Implement retry image for group chat
                  },
                ),
              ),
              ChatInputField(
                controller: _messageController,
                onSend: _sendMessage,
                onImageSend: _sendImage,
                isLoading: _isLoading,
              ),
            ],
          );
        },
      ),
    );
  }
}