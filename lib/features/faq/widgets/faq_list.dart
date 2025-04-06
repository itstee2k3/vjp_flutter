import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/models/faq.dart';
// import '../../../data/sample_data/faqs_data.dart'; // Không cần import dữ liệu mẫu ở đây nữa

class FAQList extends StatelessWidget {
  final List<FAQ> faqs; // Thêm tham số để nhận danh sách FAQs

  const FAQList({Key? key, required this.faqs}) : super(key: key); // Cập nhật constructor

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: faqs.isEmpty // Kiểm tra nếu danh sách lọc rỗng
          ? const Center(
              child: Text(
                'Không tìm thấy kết quả nào.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: faqs.length, // Sử dụng độ dài của danh sách được truyền vào
              itemBuilder: (context, index) {
                final FAQ faq = faqs[index]; // Sử dụng danh sách được truyền vào
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                  shadowColor: Colors.black12,
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      dividerColor: Colors.transparent,
                    ),
                    child: ExpansionTile(
                      iconColor: Colors.black,
                      collapsedIconColor: Colors.black,
                      title: Text(
                        faq.question,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      subtitle: Text(
                        'Ngày tạo: ${DateFormat('dd/MM/yyyy').format(faq.createdAt)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: const BorderRadius.vertical(
                              bottom: Radius.circular(16),
                            ),
                          ),
                          alignment: Alignment.topLeft,
                          child: Text(
                            faq.answer,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
