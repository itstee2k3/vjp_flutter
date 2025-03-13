import 'package:flutter/material.dart';
import '../../../data/models/faq.dart';

class FAQList extends StatelessWidget {
  const FAQList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // TODO: Replace with real data
    final faqs = [
      FAQ(
        id: '45',
        question: 'Làm thế nào để xử lý rào cản ngôn ngữ trong giao dịch kinh doanh?',
        answer: '',
        createdAt: DateTime.parse('2025-03-01'),
      ),
      FAQ(
        id: '44',
        question: 'Có những lĩnh vực nào tiềm năng cho hợp tác kinh tế giữa Việt Nam và Nhật Bản?',
        answer: '',
        createdAt: DateTime.parse('2025-03-01'),
      ),
      // Add more FAQs...
    ];

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: faqs.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final faq = faqs[index];
        return FAQItem(faq: faq);
      },
    );
  }
}

class FAQItem extends StatelessWidget {
  final FAQ faq;

  const FAQItem({
    Key? key,
    required this.faq,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Câu hỏi#${faq.id}: ',
            style: const TextStyle(
              color: Colors.blue,
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: Text(faq.question),
          ),
        ],
      ),
      trailing: Text(
        'Ngày tạo: ${faq.createdAt.day}/${faq.createdAt.month}/${faq.createdAt.year}',
        style: const TextStyle(
          fontSize: 12,
          color: Colors.grey,
        ),
      ),
      onTap: () {
        // TODO: Navigate to FAQ detail
      },
    );
  }
} 