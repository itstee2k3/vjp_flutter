import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../data/models/message.dart';
import '../../cubits/personal/personal_chat_cubit.dart';
import 'package:signalr_netcore/signalr_client.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/config/api_config.dart';
import '../../cubits/personal/personal_chat_state.dart';

class PersonalMessageScreen extends StatefulWidget {
  final String username;
  final String userId;

  const PersonalMessageScreen({
    Key? key,
    required this.username,
    required this.userId,
  }) : super(key: key);

  @override
  State<PersonalMessageScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<PersonalMessageScreen> with WidgetsBindingObserver {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  StreamSubscription<PersonalChatState>? _chatSubscription;
  late final PersonalChatCubit _chatCubit;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    _chatCubit = context.read<PersonalChatCubit>();
    if (_chatCubit.chatService.hubConnection.state != HubConnectionState.Connected) {
      _chatCubit.chatService.connect();
    }

    _chatSubscription = _chatCubit.stream.listen((state) {
      if (state.messages.isNotEmpty && mounted) {
        // Kiểm tra xem có tin nhắn hình ảnh mới không
        final hasNewImageMessage = state.messages.any((message) => 
          message.type == MessageType.image && 
          message.sentAt.isAfter(DateTime.now().subtract(Duration(seconds: 10)))
        );
        
        if (hasNewImageMessage) {
          print('New image message detected, forcing refresh');
          // Không xóa toàn bộ cache, chỉ cần setState() để cập nhật các tin nhắn mới
          setState(() {});
        }
        
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _messageController.dispose();
    _scrollController.dispose();
    _chatSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;
    
    if (state == AppLifecycleState.resumed) {
      if (_chatCubit.chatService.hubConnection.state != HubConnectionState.Connected) {
        _chatCubit.chatService.connect();
      }
    }
  }

  Future<ImageSource?> _showImageSourceDialog() async {
    // Kiểm tra nếu đang chạy trên iOS
    bool isIOS = Platform.isIOS;
    
    return await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Chọn nguồn hình ảnh'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isIOS || !isSimulator) // Chỉ hiển thị tùy chọn camera nếu không phải iOS Simulator
              ListTile(
                leading: Icon(Icons.camera_alt),
                title: Text('Chụp ảnh'),
                onTap: () => Navigator.of(context).pop(ImageSource.camera),
              ),
            ListTile(
              leading: Icon(Icons.photo_library),
              title: Text('Thư viện ảnh'),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
  }

  // Thêm getter để kiểm tra xem đang chạy trên simulator hay không
  bool get isSimulator {
    // Đây là một cách đơn giản để phát hiện simulator
    // Trên simulator, đường dẫn thường chứa "CoreSimulator"
    return Platform.isIOS && 
           Directory.current.path.toLowerCase().contains('simulator');
  }

  @override
  Widget build(BuildContext context) {
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
              final chatCubit = context.read<PersonalChatCubit>();
              chatCubit.resetAndReloadMessages();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Đang tải lại tin nhắn...')),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.sync),
            onPressed: () {
              final chatCubit = context.read<PersonalChatCubit>();
              chatCubit.loadMessages();
            },
          ),
        ],
      ),
      body: BlocListener<PersonalChatCubit, PersonalChatState>(
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
              child: BlocBuilder<PersonalChatCubit, PersonalChatState>(
                builder: (context, state) {
                  if (state.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state.messages.isEmpty) {
                    return const Center(child: Text('Chưa có tin nhắn nào'));
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(8),
                    itemCount: state.messages.length,
                    itemBuilder: (context, index) {
                      final message = state.messages[index];
                      final isMe = message.senderId == _chatCubit.chatService.currentUserId;
                      
                      return _buildMessageBubble(message, isMe);
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
                      decoration: InputDecoration(
                        hintText: 'Nhập tin nhắn...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey[200],
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.image),
                    onPressed: () async {
                      try {
                        await context.read<PersonalChatCubit>().sendImage();
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Lỗi khi gửi ảnh: $e')),
                        );
                      }
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.send),
                    onPressed: _sendMessage,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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

  @override
  void didUpdateWidget(covariant PersonalMessageScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  Future<void> _testImagePicker() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      
      if (image != null) {
        print('Test successful! Image path: ${image.path}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã chọn ảnh: ${image.path}')),
        );
      } else {
        print('No image selected in test');
      }
    } catch (e) {
      print('Test error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi test: $e')),
      );
    }
  }

  void _sendMessage() {
    if (_messageController.text.isNotEmpty) {
      context.read<PersonalChatCubit>().sendMessage(
        _messageController.text,
      );
      _messageController.clear();
    }
  }

  Widget _buildMessageBubble(Message message, bool isMe) {
    // Xử lý tin nhắn hình ảnh
    if (message.type == MessageType.image) {
      Widget imageContent;
      
      if (message.isSending) {
        // Hiển thị trạng thái đang gửi
        imageContent = Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            color: isMe ? Colors.blue.withOpacity(0.3) : Colors.grey[300],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isMe ? Colors.white : Colors.blue,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Đang gửi...',
                  style: TextStyle(
                    color: isMe ? Colors.white : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        );
      } else if (message.isError) {
        // Hiển thị trạng thái lỗi
        imageContent = Container(
          width: 200,
          decoration: BoxDecoration(
            color: Colors.red[100],
            borderRadius: BorderRadius.circular(8),
          ),
          padding: EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.error, color: Colors.red),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      message.content,
                      style: TextStyle(
                        color: Colors.red[800],
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  context.read<PersonalChatCubit>().retryImage();
                },
                child: Text('Thử lại'),
              ),
            ],
          ),
        );
      } else if (message.imageUrl != null) {
        // Hiển thị hình ảnh đã gửi thành công
        imageContent = GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => Scaffold(
                  appBar: AppBar(
                    backgroundColor: Colors.black,
                    iconTheme: IconThemeData(color: Colors.white),
                  ),
                  backgroundColor: Colors.black,
                  body: Center(
                    child: InteractiveViewer(
                      child: CachedNetworkImage(
                        imageUrl: ApiConfig.getFullImageUrl(message.imageUrl),
                        fit: BoxFit.contain,
                        placeholder: (context, url) => Center(
                          child: CircularProgressIndicator(),
                        ),
                        errorWidget: (context, url, error) => Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error, color: Colors.red, size: 48),
                            SizedBox(height: 8),
                            Text(
                              'Không thể tải hình ảnh',
                              style: TextStyle(color: Colors.white),
                            ),
                            SizedBox(height: 8),
                            Text(
                              error.toString(),
                              style: TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
          child: Column(
            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: ApiConfig.getFullImageUrl(message.imageUrl),
                  width: 200,
                  height: 200,
                  fit: BoxFit.cover,
                  cacheKey: 'image_${message.id}_${message.imageUrl}',
                  placeholder: (context, url) => Container(
                    width: 200,
                    height: 200,
                    color: isMe ? Colors.blue.withOpacity(0.3) : Colors.grey[300],
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    width: 200,
                    height: 200,
                    color: isMe ? Colors.blue.withOpacity(0.3) : Colors.grey[300],
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error, color: Colors.red),
                          SizedBox(height: 4),
                          Text(
                            'Lỗi tải ảnh',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                  key: ValueKey('image_${message.id}_${message.imageUrl}'),
                  memCacheWidth: 400,
                  maxWidthDiskCache: 400,
                  useOldImageOnUrlChange: false,
                ),
              ),
              if (message.content.isNotEmpty && message.content != '[Hình ảnh]')
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    message.content,
                    style: TextStyle(
                      color: isMe ? Colors.white : Colors.black,
                      fontSize: 14,
                    ),
                  ),
                ),
            ],
          ),
        );
      } else {
        // Trường hợp không xác định
        imageContent = Container(
          width: 200,
          height: 100,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text('Không thể hiển thị hình ảnh'),
          ),
        );
      }
      
      // Bọc nội dung hình ảnh trong container với căn chỉnh phù hợp
      return Container(
        margin: EdgeInsets.symmetric(vertical: 4),
        child: Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            padding: EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isMe ? Colors.blue : Colors.grey[200],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                imageContent,
                const SizedBox(height: 4),
                MessageTime(time: message.sentAt, isMe: isMe),
              ],
            ),
          ),
        ),
      );
    }

    // Xử lý tin nhắn văn bản
    return Container(
      margin: EdgeInsets.symmetric(vertical: 4),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isMe ? Colors.blue : Colors.grey[200],
            borderRadius: BorderRadius.circular(16),
          ),
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
          child: Column(
            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Text(
                message.content,
                style: TextStyle(
                  color: isMe ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 4),
              MessageTime(time: message.sentAt, isMe: isMe),
            ],
          ),
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
    // Format thời gian theo múi giờ địa phương
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    final formattedTime = '$hour:$minute';

    return Text(
      formattedTime,
      style: TextStyle(
        fontSize: 12,
        color: isMe ? Colors.white70 : Colors.black54,
      ),
    );
  }
} 