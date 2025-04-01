import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

mixin ChatScreenMixin<T extends StatefulWidget> on State<T> {
  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  bool isLoading = false;
  bool isInitialLoad = true;

  void scrollToBottom() {
    if (scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        scrollController.jumpTo(
          scrollController.position.maxScrollExtent,
        );
      });
    }
  }

  void setupMessageStream(Stream<dynamic> stream) {
    stream.listen((state) {
      if (mounted) {
        if (!state.isLoadingMore && !isInitialLoad) {
          scrollToBottom();
        }
      }
    });
  }

  void sendMessage(Function(String) onSend) {
    if (messageController.text.trim().isEmpty) return;

    final content = messageController.text.trim();
    messageController.clear();

    try {
      onSend(content);
      scrollToBottom();
    } catch (e) {
      print('Error sending message: $e');
    }
  }

  Future<void> sendImage(Future<void> Function() onSendImage) async {
    try {
      setState(() => isLoading = true);
      await onSendImage();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi gửi ảnh: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> loadMessages(Future<void> Function() onLoadMessages) async {
    try {
      setState(() {
        isLoading = true;
        isInitialLoad = true;
      });
      await onLoadMessages();
      
      if (mounted) {
        Future.delayed(const Duration(milliseconds: 100), () {
          scrollToBottom();
        });
      }
    } catch (e) {
      print('Error loading messages: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi tải tin nhắn: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
          isInitialLoad = false;
        });
      }
    }
  }

  @override
  void dispose() {
    messageController.dispose();
    scrollController.dispose();
    super.dispose();
  }
} 