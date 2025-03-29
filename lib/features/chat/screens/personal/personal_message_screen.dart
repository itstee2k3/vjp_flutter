import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:signalr_netcore/hub_connection.dart';
import '../../../../data/models/message.dart';
import '../../cubits/personal/personal_chat_cubit.dart';
import '../../cubits/personal/personal_chat_state.dart';
import '../../widgets/chat_input_field.dart';
import '../../widgets/message_list.dart';
import '../../widgets/text_message_bubble.dart';
import '../../widgets/image_message_bubble.dart';

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
  bool _isTyping = false;
  Timer? _typingTimer;
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
    _typingTimer?.cancel();
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

  void _handleTyping(String text) {
    if (!_isTyping) {
      _isTyping = true;
      context.read<PersonalChatCubit>().sendTypingStatus(widget.userId, true);
    }

    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), () {
      _isTyping = false;
      context.read<PersonalChatCubit>().sendTypingStatus(widget.userId, false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              child: Text(widget.username[0].toUpperCase()),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.username),
                  BlocBuilder<PersonalChatCubit, PersonalChatState>(
                    builder: (context, state) {
                      if (state.typingStatus[widget.userId] == true) {
                        return const Text(
                          'Đang nhập...',
                          style: TextStyle(fontSize: 12),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<PersonalChatCubit>().resetAndReloadMessages();
            },
          ),
        ],
      ),
      body: BlocBuilder<PersonalChatCubit, PersonalChatState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(8),
                  itemCount: state.messages.length,
                  itemBuilder: (context, index) {
                    final message = state.messages[index];
                    final isMe = message.senderId == context.read<PersonalChatCubit>().chatService.currentUserId;
                    final showAvatar = index == 0 ||
                        state.messages[index - 1].senderId != message.senderId;

                    if (message.type == MessageType.image) {
                      return ImageMessageBubble(
                        message: message,
                        isMe: isMe,
                        onRetry: () => context.read<PersonalChatCubit>().retryImage(),
                      );
                    }

                    return TextMessageBubble(
                      message: message,
                      isMe: isMe,
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.photo),
                        onPressed: _sendImage,
                      ),
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          decoration: const InputDecoration(
                            hintText: 'Nhập tin nhắn...',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                          ),
                          onChanged: _handleTyping,
                          onSubmitted: (_) => _sendMessage(),
                          textCapitalization: TextCapitalization.sentences,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: _sendMessage,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
