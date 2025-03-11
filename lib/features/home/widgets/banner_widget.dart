import 'package:flutter/material.dart';

class BannerWidget extends StatelessWidget {
  const BannerWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Image.network(
      'https://vjp-connect.com/_next/static/media/vjp-connect-banner-sm.eed45626.webp',
      width: double.infinity,
      height: 200, // Thêm chiều cao cố định
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: double.infinity,
          height: 200,
          color: Colors.grey[200],
          child: const Center(
            child: Text('Không thể tải hình ảnh'),
          ),
        );
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          width: double.infinity,
          height: 200,
          color: Colors.grey[200],
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
    );
  }
} 