import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = "http://127.0.0.1:5294/api/auth";



  // Đăng nhập
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "password": password}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'],
          'accessToken': data['accessToken'],
          'refreshToken': data['refreshToken'],
          'fullName': data['fullName'] ?? 'User',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Đăng nhập thất bại',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Lỗi kết nối: ${e.toString()}',
      };
    }
  }


  // Đăng ký
  Future<Map<String, dynamic>> register(String fullName, String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/register"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "fullName": fullName,
          "email": email,
          "password": password
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message':  jsonDecode(response.body)['message'] ?? 'Đăng ký thành công',
          'data': jsonDecode(response.body)
        };
      } else {
        return {
          'success': false,
          'message': jsonDecode(response.body)['message'] ?? 'Đăng ký thất bại'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: ${e.toString()}'};
    }
  }

  // Đăng xuất
  Future<Map<String, dynamic>> logout(String accessToken, String refreshToken) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/logout"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $accessToken"
        },
        body: jsonEncode({"refreshToken": refreshToken}),
      );

      print('Logout response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Đăng xuất thành công'};
      } else {
        return {
          'success': false,
          'message': 'Đăng xuất thất bại: ${response.body}',
        };
      }
    } catch (e) {
      print('Error during logout: $e');
      return {'success': false, 'message': 'Lỗi kết nối: ${e.toString()}'};
    }
  }
}
