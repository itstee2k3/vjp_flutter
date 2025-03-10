import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

class ApiConfig {
  static String get baseUrl {
    // Kiểm tra web trước
    if (kIsWeb) {
      return 'http://localhost:5294';
    }

    // Sau đó mới kiểm tra mobile platforms
    try {
      if (Platform.isIOS) {
        return 'http://127.0.0.1:5294'; // iOS simulator
      } else if (Platform.isAndroid) {
        return 'http://10.0.2.2:5294'; // Android emulator
      }
    } catch (e) {
      print('Platform check error: $e');
    }

    // Default URL
    return 'http://localhost:5294'; // Web & others
  }

  static String get loginUrl => '$baseUrl/api/auth/login';
  static String get registerUrl => '$baseUrl/api/auth/register';
  static String get logoutUrl => '$baseUrl/api/auth/logout';
  // Thêm các endpoint khác nếu cần
} 