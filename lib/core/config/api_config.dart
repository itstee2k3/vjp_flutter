import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

class ApiConfig {
  static String get baseUrl {
    // Kiểm tra web trước
    if (kIsWeb) {
      return 'http://localhost:5294';
    }

    // Sau đó kiểm tra mobile platforms
    try {
      if (Platform.isIOS) {
        return 'http://127.0.0.1:5294'; // iOS simulator
      } else if (Platform.isAndroid) {
        // Sử dụng IP cho thiết bị thật Android
        return 'http://192.168.0.252:5294'; // Thiết bị Android thật
      }
    } catch (e) {
      print('Platform check error: $e');
    }

    // Dùng URL ngrok
    return 'https://jsonplaceholder.typicode.com'; // API test
  }

  // Các URL khác
  static String get loginUrl => '$baseUrl/api/auth/login';
  static String get registerUrl => '$baseUrl/api/auth/register';
  static String get logoutUrl => '$baseUrl/api/auth/logout';
  static String get refreshTokenUrl => '$baseUrl/api/auth/refresh-token';
  
  // Phương thức xử lý URL hình ảnh
  static String getFullImageUrl(String? imageUrl) {
    // Nếu imageUrl là null hoặc rỗng, trả về một URL mặc định hoặc chuỗi rỗng
    if (imageUrl == null || imageUrl.isEmpty) {
      return ''; // Hoặc URL mặc định
    }

    // Nếu imageUrl đã là URL đầy đủ (bắt đầu bằng http:// hoặc https://)
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      // Kiểm tra nếu URL chứa localhost hoặc 127.0.0.1
      if (imageUrl.contains('localhost') || imageUrl.contains('127.0.0.1')) {
        // Thay thế domain cố định bằng baseUrl hiện tại
        final path = Uri.parse(imageUrl).path;
        return '$baseUrl$path';
      }
      return imageUrl;
    }
    
    // Nếu imageUrl là đường dẫn tương đối (bắt đầu bằng /)
    if (imageUrl.startsWith('/')) {
      return '$baseUrl$imageUrl';
    }
    
    // Nếu imageUrl là đường dẫn tương đối (không bắt đầu bằng /)
    return '$baseUrl/$imageUrl';
  }
}
