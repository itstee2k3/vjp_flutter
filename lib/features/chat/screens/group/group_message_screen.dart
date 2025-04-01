import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../data/models/message.dart';
import '../../cubits/group/group_chat_cubit.dart';
import '../../cubits/group/group_chat_state.dart';
import '../../widgets/chat_input_field.dart';
import '../../widgets/message_list.dart';
import '../../widgets/chat_header.dart';
import '../../mixins/chat_screen_mixin.dart';
import 'package:image_picker/image_picker.dart';

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

class _GroupMessageScreenState extends State<GroupMessageScreen> with ChatScreenMixin {
  final _imagePicker = ImagePicker();
  File? _selectedImage;
  String _imageCaption = '';
  bool _showImagePreview = false;
  
  @override
  void initState() {
    super.initState();
    loadMessages(() => context.read<GroupChatCubit>().loadMessages());
    setupMessageStream(context.read<GroupChatCubit>().stream);
  }

  void _retryImageUpload(Message message) {
    // Implement retry image upload logic
    print('Retrying image upload for message: ${message.id}');
    // You can add implementation for retrying failed uploads
  }

  void _viewGroupInfo() {
    // Navigate to group info screen
    print('Viewing group info for group ${widget.groupId}');
    // Implement navigation to group info screen
  }
  
  Future<void> _pickImage() async {
    try {
      // Ask user to choose between camera and gallery
      final source = await showDialog<ImageSource>(
        context: context,
        builder: (BuildContext context) {
          return SimpleDialog(
            title: const Text('Chọn nguồn ảnh'),
            children: <Widget>[
              SimpleDialogOption(
                onPressed: () => Navigator.pop(context, ImageSource.camera),
                child: const Text('Máy ảnh'),
              ),
              SimpleDialogOption(
                onPressed: () => Navigator.pop(context, ImageSource.gallery),
                child: const Text('Thư viện ảnh'),
              ),
            ],
          );
        },
      );
      
      if (source == null) return;
      
      final pickedFile = await _imagePicker.pickImage(
        source: source,
        imageQuality: 70,
      );
      
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
          _showImagePreview = true;
          _imageCaption = '';
        });
      }
    } catch (e) {
      print('Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi chọn ảnh: $e')),
      );
    }
  }
  
  void _cancelImageUpload() {
    setState(() {
      _selectedImage = null;
      _showImagePreview = false;
      _imageCaption = '';
    });
  }
  
  Future<void> _sendImage() async {
    if (_selectedImage == null) return;
    
    try {
      final cubit = context.read<GroupChatCubit>();
      await cubit.sendImageMessage(_imageCaption, _selectedImage!);
      
      // Clear the image preview after sending
      setState(() {
        _selectedImage = null;
        _showImagePreview = false;
        _imageCaption = '';
      });
    } catch (e) {
      print('Error sending image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi gửi ảnh: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: ChatHeader(
          title: widget.groupName,
          isGroup: true,
          onRefreshPressed: () {
            // Reset and reload messages
            print('Refreshing group messages');
            context.read<GroupChatCubit>().resetAndReloadMessages();
          },
          onInfoPressed: _viewGroupInfo,
        ),
      ),
      body: BlocBuilder<GroupChatCubit, GroupChatState>(
        builder: (context, state) {
          if (state.isLoading && state.messages.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Đang tải tin nhắn...'),
                ],
              )
            );
          }

          if (state.error != null && state.messages.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Lỗi: ${state.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.read<GroupChatCubit>().loadMessages(),
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: MessageList(
                  messages: state.messages,
                  currentUserId: state.currentUserId ?? '',
                  scrollController: scrollController,
                  onRetryImage: () => {}, // Simple empty callback for backward compatibility
                  onRetryImageWithMessage: (message) => _retryImageUpload(message),
                  hasMoreMessages: state.hasMoreMessages,
                  isLoadingMore: state.isLoadingMore,
                  onLoadMore: () => context.read<GroupChatCubit>().loadMoreMessages(),
                ),
              ),
              if (state.error != null && state.messages.isNotEmpty)
                Container(
                  color: Colors.red[100],
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(child: Text('Lỗi: ${state.error}', style: const TextStyle(color: Colors.red))),
                      IconButton(
                        icon: const Icon(Icons.refresh, color: Colors.red),
                        onPressed: () => context.read<GroupChatCubit>().loadMessages(),
                      ),
                    ],
                  ),
                ),
              if (_showImagePreview)
                _buildImagePreview(),
              if (!_showImagePreview)
                ChatInputField(
                  controller: messageController,
                  onSend: () => sendMessage((content) => context.read<GroupChatCubit>().sendMessage(content)),
                  onImageSend: _pickImage,
                  isLoading: state.isSending,
                ),
            ],
          );
        },
      ),
    );
  }
  
  Widget _buildImagePreview() {
    return Container(
      color: Colors.grey[200],
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Text('Gửi hình ảnh', style: TextStyle(fontWeight: FontWeight.bold)),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: _cancelImageUpload,
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              _selectedImage!,
              height: 200,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            decoration: const InputDecoration(
              hintText: 'Thêm chú thích (không bắt buộc)',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              setState(() {
                _imageCaption = value;
              });
            },
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _sendImage,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.send),
                SizedBox(width: 8),
                Text('Gửi hình ảnh'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}