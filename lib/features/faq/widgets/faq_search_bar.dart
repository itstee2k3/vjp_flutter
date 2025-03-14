import 'package:flutter/material.dart';

class FAQSearchBar extends StatelessWidget {
  final Function(String)? onSearch;

  const FAQSearchBar({
    Key? key,
    this.onSearch,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        onChanged: onSearch,
        decoration: const InputDecoration(
          hintText: 'Tìm kiếm câu hỏi...',
          prefixIcon: Icon(Icons.search, color: Colors.blue),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }
} 