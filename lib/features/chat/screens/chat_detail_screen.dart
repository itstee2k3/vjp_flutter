import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_socket_io/features/auth/cubits/auth_cubit.dart';
import '../cubits/chat_cubit.dart';
import 'package:signalr_netcore/signalr_client.dart';

class ChatDetailScreen extends StatefulWidget {
  final String username;
  final String userId;

  const ChatDetailScreen({
    Key? key,
    required this.username,
    required this.userId,
  }) : super(key: key);

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> with WidgetsBindingObserver {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  StreamSubscription<ChatState>? _chatSubscription;
  Timer? _connectionCheckTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    print('ChatDetailScreen initialized for user: ${widget.userId}');

    // Kiểm tra kết nối SignalR
    final chatCubit = context.read<ChatCubit>();
    if (chatCubit.chatService.hubConnection.state != HubConnectionState.Connected) {
      print('SignalR not connected in ChatDetailScreen, connecting...');
      chatCubit.chatService.connect();
    }

    // Đồng bộ tin nhắn khi vào màn hình
    WidgetsBinding.instance.addPostFrameCallback((_) {
      chatCubit.syncMessages();
    });

    _chatSubscription?.cancel();
    
    _chatSubscription = context.read<ChatCubit>().stream.listen((state) {
      if (state.messages.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });
      }
    });

    // Thêm kiểm tra kết nối định kỳ
    _startConnectionCheck();

    // Thêm lắng nghe sự kiện từ máy chủ
    chatCubit.chatService.hubConnection.on('NewMessageNotification', (arguments) {
      print('Received NewMessageNotification, syncing messages immediately');
      chatCubit.syncMessages();
    });
  }

  void _startConnectionCheck() {
    _connectionCheckTimer?.cancel();
    _connectionCheckTimer = Timer.periodic(Duration(seconds: 10), (timer) async {
      final chatCubit = context.read<ChatCubit>();
      if (chatCubit.chatService.hubConnection.state != HubConnectionState.Connected) {
        print('Periodic check in ChatDetailScreen: SignalR not connected, reconnecting...');
        await chatCubit.chatService.connect();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _messageController.dispose();
    _scrollController.dispose();
    _chatSubscription?.cancel();
    _connectionCheckTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      print('App resumed, syncing messages');
      final chatCubit = context.read<ChatCubit>();
      chatCubit.syncMessages();
      
      // Kiểm tra kết nối SignalR
      if (chatCubit.chatService.hubConnection.state != HubConnectionState.Connected) {
        print('App resumed: SignalR not connected, reconnecting...');
        chatCubit.chatService.connect();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatCubit = context.read<ChatCubit>();
    final currentUserId = chatCubit.chatService.currentUserId;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.username),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              final chatCubit = context.read<ChatCubit>();
              chatCubit.resetAndReloadMessages();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Đang tải lại tin nhắn...')),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.sync),
            onPressed: () {
              final chatCubit = context.read<ChatCubit>();
              chatCubit.syncMessages();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Đang đồng bộ tin nhắn...')),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: BlocConsumer<ChatCubit, ChatState>(
              listener: (context, state) {
                // Auto scroll when new message arrives
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) {
                    _scrollController.animateTo(
                      _scrollController.position.maxScrollExtent,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                  }
                });
              },
              builder: (context, state) {
                if (state.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(8),
                  itemCount: state.messages.length,
                  itemBuilder: (context, index) {
                    final message = state.messages[index];
                    final isMe = message.senderId == currentUserId;
                    
                    return MessageBubble(
                      message: message.content,
                      isMe: isMe,
                      time: message.sentAt,
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(20)),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send),
                  color: Colors.blue,
                  onPressed: () {
                    if (_messageController.text.isNotEmpty) {
                      context.read<ChatCubit>().sendMessage(
                        _messageController.text,
                      );
                      _messageController.clear();
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void didUpdateWidget(covariant ChatDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }
}

class MessageBubble extends StatelessWidget {
  final String message;
  final bool isMe;
  final DateTime time;

  const MessageBubble({
    Key? key,
    required this.message,
    required this.isMe,
    required this.time,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          left: isMe ? 64 : 8,
          right: isMe ? 8 : 64,
          top: 4,
          bottom: 4,
        ),
        padding: const EdgeInsets.symmetric(
          vertical: 8,
          horizontal: 12,
        ),
        decoration: BoxDecoration(
          color: isMe ? Colors.blue : Colors.grey[300],
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 3,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: TextStyle(
                color: isMe ? Colors.white : Colors.black,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            MessageTime(time: time, isMe: isMe),
          ],
        ),
      ),
    );
  }
}

class MessageTime extends StatelessWidget {
  final DateTime time;
  final bool isMe;

  const MessageTime({
    Key? key,
    required this.time,
    required this.isMe,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Server đã trả về thời gian Việt Nam, chỉ cần format
    final formattedTime = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

    return Text(
      formattedTime,
      style: TextStyle(
        fontSize: 12,
        color: isMe ? Colors.white70 : Colors.black54,
      ),
    );
  }
} 