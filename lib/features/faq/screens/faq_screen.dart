import 'package:flutter/material.dart';
import '../../../data/models/faq.dart';
import '../../../data/sample_data/faqs_data.dart';
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

class FAQScreen extends StatefulWidget {
  const FAQScreen({Key? key}) : super(key: key);

  @override
  State<FAQScreen> createState() => _FAQScreenState();
}

class _FAQScreenState extends State<FAQScreen> {
  String _searchQuery = '';
  List<FAQ> _filteredFaqs = faqItems;

  @override
  void initState() {
    super.initState();
    _filteredFaqs = faqItems;
  }

  void _filterFaqs(String query) {
    final normalizedQuery = _removeDiacritics(query.toLowerCase());
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredFaqs = faqItems;
      } else {
        _filteredFaqs = faqItems
            .where((faq) {
              final normalizedQuestion = _removeDiacritics(faq.question.toLowerCase());
              final normalizedAnswer = _removeDiacritics(faq.answer.toLowerCase());
              return normalizedQuestion.contains(normalizedQuery) ||
                     normalizedAnswer.contains(normalizedQuery);
            })
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.only(left: 30, right: 30, top: 30, bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'Các câu hỏi thường gặp trong kết nối - giao thương Việt Nam - Nhật Bản',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.blueAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FAQSearchBar(onSearch: _filterFaqs),
                ],
              ),
            ),
          ),
          SliverFillRemaining(
            child: FAQList(faqs: _filteredFaqs),
          ),
        ],
      ),
    );
  }
} 