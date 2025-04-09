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
    print('🔍 Processing image URL: $imageUrl');
    
    // Nếu imageUrl là null hoặc rỗng, trả về chuỗi rỗng
    if (imageUrl == null || imageUrl.isEmpty) {
      print('⚠️ Image URL is null or empty');
      return '';
    }

    // Nếu imageUrl đã là URL đầy đủ (bắt đầu bằng http:// hoặc https://)
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      print('✓ URL is already complete: $imageUrl');
      return imageUrl;
    }

    // Đảm bảo imageUrl bắt đầu bằng /
    String normalizedPath = imageUrl.startsWith('/') ? imageUrl : '/$imageUrl';
    print('📝 Normalized path: $normalizedPath');
    
    // Kết hợp với baseUrl
    String fullUrl = baseUrl + normalizedPath;
    print('✓ Generated full URL: $fullUrl');
    return fullUrl;
  }
  
  // Avatar mặc định cho user nếu không có avatar
  static String get defaultUserAvatar => 'assets/avatar_default/avatar_default.png';
  
  // Avatar mặc định cho group nếu không có avatar
  static String get defaultGroupAvatar => 'assets/avatar_default/avatar_group_default.png';
}
