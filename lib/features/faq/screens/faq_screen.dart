import 'package:flutter/material.dart';
import '../widgets/faq_search_bar.dart';
import '../widgets/faq_list.dart';

class FAQScreen extends StatelessWidget {
  const FAQScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'FAQ',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'Các câu hỏi thường gặp trong kết nối - giao thương Việt Nam - Nhật Bản',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 16),
                const FAQSearchBar(),
              ],
            ),
          ),
          const Expanded(
            child: FAQList(),
          ),
        ],
      ),
    );
  }
} 