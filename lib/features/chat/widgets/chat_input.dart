import 'package:flutter/material.dart';
import 'dart:async';

class ChatInput extends StatefulWidget {
  final Function(String) onSendMessage;
  final VoidCallback onTypingStarted;
  final VoidCallback onTypingStopped;

  const ChatInput({
    Key? key,
    required this.onSendMessage,
    required this.onTypingStarted,
    required this.onTypingStopped,
  }) : super(key: key);

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  final _textController = TextEditingController();
  Timer? _typingTimer;
  bool _isTyping = false;

  @override
  void dispose() {
    _textController.dispose();
    _typingTimer?.cancel();
    super.dispose();
  }

  void _handleTyping() {
    if (!_isTyping) {
      _isTyping = true;
      widget.onTypingStarted();
    }

    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(milliseconds: 500), () {
      _isTyping = false;
      widget.onTypingStopped();
    });
  }

  void _handleSend() {
    final message = _textController.text.trim();
    if (message.isNotEmpty) {
      widget.onSendMessage(message);
      _textController.clear();
      _isTyping = false;
      widget.onTypingStopped();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.attach_file),
              onPressed: () {
                // Show attachment options
              },
            ),
            Expanded(
              child: TextField(
                controller: _textController,
                onChanged: (_) => _handleTyping(),
                decoration: const InputDecoration(
                  hintText: 'Type a message',
                  border: InputBorder.none,
                ),
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.send),
              onPressed: _handleSend,
            ),
          ],
        ),
      ),
    );
  }
} 