import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/models/faq.dart';
import '../../../data/sample_data/faqs_data.dart';

class FAQList extends StatelessWidget {
  const FAQList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: faqItems.length,
      itemBuilder: (context, index) {
        final FAQ faq = faqItems[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 8,
          shadowColor: Colors.black26,
          child: Theme(
            data: Theme.of(context).copyWith(
              dividerColor: Colors.transparent, // Ẩn đường gạch dưới nội dung mở rộng
            ),
            child: ExpansionTile(
              iconColor: Colors.blueAccent,
              collapsedIconColor: Colors.blueAccent,
              title: Text(
                faq.question,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              subtitle: Text(
                'Ngày tạo: ${DateFormat('dd/MM/yyyy').format(faq.createdAt)}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(16),
                    ),
                  ),
                  alignment: Alignment.topLeft,
                  child: Text(
                    faq.answer,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
