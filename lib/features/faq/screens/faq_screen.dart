import 'package:flutter/material.dart';
import '../widgets/faq_search_bar.dart';
import '../widgets/faq_list.dart';

class FAQScreen extends StatelessWidget {
  const FAQScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: const Text('FAQ'),
            centerTitle: true,
            backgroundColor: Colors.white,
            pinned: true,
            elevation: 0,
          ),
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'Các câu hỏi thường gặp trong kết nối - giao thương Việt Nam - Nhật Bản',
                    textAlign: TextAlign.center,
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
          ),
          const SliverFillRemaining(
            child: FAQList(),
          ),
        ],
      ),
    );
  }
} 