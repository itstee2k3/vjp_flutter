import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/api/api_service.dart';
import 'auth_state.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AuthCubit extends Cubit<AuthState> {
  final ApiService _apiService;
  final SharedPreferences prefs;

  static const String KEY_ACCESS_TOKEN = 'access_token';
  static const String KEY_REFRESH_TOKEN = 'refresh_token';
  static const String KEY_EMAIL = 'email';
  static const String KEY_FULL_NAME = 'full_name';
  static const String KEY_USER_ID = 'user_id';

  AuthCubit({required this.prefs, required ApiService apiService})
    : _apiService = apiService,
      super(AuthState()) {
    checkAuthStatus(); // Kiểm tra trạng thái auth khi khởi tạo
  }

  Future<void> checkAuthStatus() async {
    final accessToken = prefs.getString(KEY_ACCESS_TOKEN);
    final refreshToken = prefs.getString(KEY_REFRESH_TOKEN);
    final userId = prefs.getString(KEY_USER_ID);

    if (accessToken != null && refreshToken != null) {
      // Tạo response map để parse thông tin từ token
      final response = {
        'success': true,
        'accessToken': accessToken,
        'refreshToken': refreshToken,
        'userId': userId,
      };

      emit(AuthState.fromJson(response));
    }
  }

  Future<void> loginSuccess(Map<String, dynamic> response) async {
    try {
      final accessToken = response['accessToken'];
      print('Saving token: $accessToken'); // Debug log

      if (accessToken != null) {
        await prefs.setString(KEY_ACCESS_TOKEN, accessToken);
      }
      if (response['refreshToken'] != null) {
        await prefs.setString(KEY_REFRESH_TOKEN, response['refreshToken']);
      }
      if (response['email'] != null) {
        await prefs.setString(KEY_EMAIL, response['email']);
      }
      if (response['fullName'] != null) {
        await prefs.setString(KEY_FULL_NAME, response['fullName']);
      }
      
      // Tạo AuthState để trích xuất userId từ token
      final authState = AuthState.fromJson(response);
      
      // Lưu userId nếu có
      if (authState.userId != null) {
        await prefs.setString(KEY_USER_ID, authState.userId!);
        print('Đã lưu userId: ${authState.userId}');
      }

      emit(authState);
    } catch (e) {
      print('Error in loginSuccess: $e');
      // Emit default state if error occurs
      emit(AuthState(isAuthenticated: true));
    }
  }

  Future<void> logout() async {
    try {
      final accessToken = state.accessToken;
      final refreshToken = state.refreshToken;
      
      if (accessToken != null && refreshToken != null) {
        await _apiService.logout(accessToken, refreshToken);
      }
      
      // Xóa token khỏi bộ nhớ
      await prefs.remove(KEY_ACCESS_TOKEN);
      await prefs.remove(KEY_REFRESH_TOKEN);
      await prefs.remove(KEY_EMAIL);
      await prefs.remove(KEY_FULL_NAME);
      await prefs.remove(KEY_USER_ID);

      emit(AuthState());
    } catch (e) {
      print('Error during logout: $e');
      // Vẫn xóa token khỏi bộ nhớ ngay cả khi có lỗi
      await prefs.remove(KEY_ACCESS_TOKEN);
      await prefs.remove(KEY_REFRESH_TOKEN);
      await prefs.remove(KEY_EMAIL);
      await prefs.remove(KEY_FULL_NAME);
      await prefs.remove(KEY_USER_ID);
      emit(AuthState());
    }
  }
}