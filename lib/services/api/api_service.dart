import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import '../../core/config/api_config.dart';
import 'package:flutter/foundation.dart';

class ApiService {
  late final Dio dio;

  ApiService() {
    dio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        if (kIsWeb) 'Access-Control-Allow-Origin': '*',
      },
    ));

    print('API Service initialized with base URL: ${ApiConfig.baseUrl}');
  }

  // Đăng nhập
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await dio.post(
        ApiConfig.loginUrl,
        data: {
          'email': email,
          'password': password,
        },
      );

      return {
        'success': true,
        'accessToken': response.data['accessToken'],
        'refreshToken': response.data['refreshToken'],
        'userId': response.data['userId'],
      };
    } catch (e) {
      if (e is DioException) {
        // Lấy message từ response error
        final errorMessage = e.response?.data['message'] ?? 'Đã có lỗi xảy ra';
        
        return {
          'success': false,
          'message': errorMessage,
        };
      }
      rethrow;
    }
  }

  // Đăng ký
  Future<Map<String, dynamic>> register(String fullName, String email, String password) async {
    try {
      final response = await dio.post(
        ApiConfig.registerUrl,
        data: {
          'fullName': fullName,
          'email': email,
          'password': password,
        },
      );

      return {
        'success': true,
        'message': response.data['message'] ?? 'Đăng ký thành công',
        'data': response.data
      };
    } catch (e) {
      if (e is DioException) {
        // Lấy message từ response nếu có, nếu không có thì trả về lỗi mặc định
        final errorMessage = e.response?.data['message'] ?? 'Đã có lỗi xảy ra';

        return {
          'success': false,
          'message': errorMessage,
        };
      }
      rethrow;
    }
  }


  // Đăng xuất
  Future<Map<String, dynamic>> logout(String accessToken, String refreshToken) async {
    try {
      final response = await dio.post(
        ApiConfig.logoutUrl,
        data: {
          'refreshToken': refreshToken,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $accessToken',
          },
        ),
      );

      print('Logout response: ${response.statusCode} - ${response.data}');

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Đăng xuất thành công'
        };
      } else {
        return {
          'success': false,
          'message': 'Đăng xuất thất bại: ${response.data}',
        };
      }
    } catch (e) {
      print('Logout error: $e');
      return {
        'success': false,
        'message': 'Lỗi kết nối: ${e.toString()}'
      };
    }
  }

  Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    try {
      final response = await dio.post(
        '${ApiConfig.baseUrl}/api/auth/refresh-token',
        data: {
          'refreshToken': refreshToken,
        },
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'accessToken': response.data['accessToken'],
          'refreshToken': response.data['refreshToken'],
        };
      } else {
        return {
          'success': false,
          'message': 'Không thể làm mới token',
        };
      }
    } catch (e) {
      print('Refresh token error: $e');
      return {
        'success': false,
        'message': 'Lỗi kết nối khi làm mới token',
      };
    }
  }
}
