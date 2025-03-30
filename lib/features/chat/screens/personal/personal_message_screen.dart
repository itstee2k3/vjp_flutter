import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubits/personal/personal_chat_cubit.dart';
import '../../cubits/personal/personal_chat_state.dart';
import '../../widgets/chat_header.dart';
import '../../widgets/chat_input_field.dart';
import '../../widgets/message_list.dart';

class PersonalMessageScreen extends StatefulWidget {
  final String username;
  final String userId;

  const PersonalMessageScreen({
    Key? key,
    required this.username,
    required this.userId,
  }) : super(key: key);

  @override
  State<PersonalMessageScreen> createState() => _PersonalMessageScreenState();
}

class _PersonalMessageScreenState extends State<PersonalMessageScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _setupMessageStream();
    _scrollToBottom();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
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

  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);
    try {
      await context.read<PersonalChatCubit>().loadMessages();
    } catch (e) {
      print('Error loading messages: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _setupMessageStream() {
    final chatCubit = context.read<PersonalChatCubit>();
    chatCubit.stream.listen((state) {
      if (state.messages.isNotEmpty && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });
      }
    });
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    final content = _messageController.text.trim();
    _messageController.clear();

    try {
      context.read<PersonalChatCubit>().sendMessage(content);
      _scrollToBottom();
    } catch (e) {
      print('Error sending message: $e');
    }
  }

  Future<void> _sendImage() async {
    try {
      await context.read<PersonalChatCubit>().sendImage();
      _scrollToBottom();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi gửi ảnh: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: BlocBuilder<PersonalChatCubit, PersonalChatState>(
          builder: (context, state) {
            return ChatHeader(
              title: widget.username,
              onRefreshPressed: () {
                context.read<PersonalChatCubit>().resetAndReloadMessages();
              },
              onInfoPressed: () {
                // TODO: Navigate to group info screen
              },
            );
          },
        ),
      ),
      body: BlocBuilder<PersonalChatCubit, PersonalChatState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              Expanded(
                child: MessageList(
                  messages: state.messages,
                  currentUserId: context.read<PersonalChatCubit>().chatService.currentUserId ?? '',
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
