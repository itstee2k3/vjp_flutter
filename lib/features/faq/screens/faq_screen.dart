import 'package:flutter/material.dart';
import '../../../data/models/faq.dart'; // Import FAQ model
import '../../../data/sample_data/faqs_data.dart'; // Import sample data
import '../widgets/faq_search_bar.dart';
import '../widgets/faq_list.dart';

// Hàm tiện ích để loại bỏ dấu tiếng Việt
String _removeDiacritics(String str) {
  var withDia = 'àáãảạăằắẳẵặâầấẩẫậèéẻẽẹêềếểễệđìíỉĩịòóõỏọôồốổỗộơờớởỡợùúủũụưừứửữựỳýỷỹỵ';
  var withoutDia = 'aaaaaaaaaaaaaaaaaeeeeeeeeeeediiiiiooooooooooooooooouuuuuuuuuuuyyyyy';

  for (int i = 0; i < withDia.length; i++) {
    str = str.replaceAll(withDia[i], withoutDia[i]);
    str = str.replaceAll(withDia[i].toUpperCase(), withoutDia[i].toUpperCase());
  }
  return str;
}

class FAQScreen extends StatefulWidget { // Chuyển thành StatefulWidget
  const FAQScreen({Key? key}) : super(key: key);

  @override
  State<FAQScreen> createState() => _FAQScreenState();
}

class _FAQScreenState extends State<FAQScreen> { // Tạo State
  String _searchQuery = '';
  List<FAQ> _filteredFaqs = faqItems; // Khởi tạo với toàn bộ danh sách

  @override
  void initState() {
    super.initState();
    _filteredFaqs = faqItems; // Đảm bảo danh sách được khởi tạo
  }

  void _filterFaqs(String query) {
    final normalizedQuery = _removeDiacritics(query.toLowerCase());
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredFaqs = faqItems; // Nếu query rỗng, hiển thị tất cả
      } else {
        _filteredFaqs = faqItems
            .where((faq) {
              final normalizedQuestion = _removeDiacritics(faq.question.toLowerCase());
              final normalizedAnswer = _removeDiacritics(faq.answer.toLowerCase());
              return normalizedQuestion.contains(normalizedQuery) ||
                     normalizedAnswer.contains(normalizedQuery);
            })
            .toList(); // Lọc theo câu hỏi hoặc câu trả lời
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const SliverAppBar(
            expandedHeight: 100.0, // Tăng chiều cao của SliverAppBar để có đủ không gian
            pinned: true, // Giữ SliverAppBar luôn hiển thị khi cuộn
            backgroundColor: Colors.white,
            elevation: 0,
            centerTitle: true, // Căn giữa tiêu đề trong SliverAppBar
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Các câu hỏi thường gặp trong kết nối - giao thương Việt Nam - Nhật Bản',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center, // Căn giữa tiêu đề
              ),
              // titlePadding: EdgeInsets.symmetric(horizontal: 16.0), // Đảm bảo padding hợp lý cho tiêu đề
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.only(left: 30, right: 30, top: 10, bottom: 10),
              child: Column( // Bọc trong Column để thêm FAQSearchBar
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 16),
                  FAQSearchBar(onSearch: _filterFaqs), // Truyền hàm callback
                ],
              ),
            ),
          ),
          SliverFillRemaining(
            child: FAQList(faqs: _filteredFaqs), // Truyền danh sách đã lọc
          ),
        ],
      ),
    );
  }
} 