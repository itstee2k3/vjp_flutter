import 'package:flutter/material.dart';

class FAQSearchBar extends StatelessWidget {
  const FAQSearchBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextField(
      decoration: InputDecoration(
        hintText: 'Hãy nhập câu hỏi của bạn?',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: IconButton(
          icon: const Icon(Icons.chat),
          onPressed: () {
            // TODO: Mở VJP-Connect AI Chatbot
          },
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      onChanged: (value) {
        // TODO: Implement search
      },
    );
  }
} 