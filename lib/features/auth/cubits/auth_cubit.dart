import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/api/api_service.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final ApiService _apiService;
  final SharedPreferences prefs;
  
  static const String KEY_ACCESS_TOKEN = 'access_token';
  static const String KEY_REFRESH_TOKEN = 'refresh_token';
  static const String KEY_EMAIL = 'email';
  static const String KEY_FULL_NAME = 'full_name';

  AuthCubit({required this.prefs, required ApiService apiService}) 
    : _apiService = apiService,
      super(const AuthState()) {
    checkAuthStatus(); // Kiểm tra trạng thái auth khi khởi tạo
  }

  Future<void> checkAuthStatus() async {
    final accessToken = prefs.getString(KEY_ACCESS_TOKEN);
    final refreshToken = prefs.getString(KEY_REFRESH_TOKEN);

    if (accessToken != null && refreshToken != null) {
      // Tạo response map để parse thông tin từ token
      final response = {
        'success': true,
        'accessToken': accessToken,
        'refreshToken': refreshToken,
      };
      
      emit(AuthState.fromJson(response));
    }
  }

  Future<void> loginSuccess(Map<String, dynamic> response) async {
    try {
      // Lưu thông tin vào SharedPreferences
      if (response['accessToken'] != null) {
        await prefs.setString(KEY_ACCESS_TOKEN, response['accessToken']);
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

      emit(AuthState.fromJson(response));
    } catch (e) {
      print('Error saving auth data: $e');
      // Emit default state if error occurs
      emit(const AuthState(isAuthenticated: true));
    }
  }

  Future<void> logout() async {
    try {
      await _apiService.logout();
    } catch (e) {
      print('Logout error: $e');
    }
    
    // Luôn xóa thông tin local
    await prefs.remove(KEY_ACCESS_TOKEN);
    await prefs.remove(KEY_REFRESH_TOKEN);
    await prefs.remove(KEY_EMAIL);
    await prefs.remove(KEY_FULL_NAME);
    
    emit(const AuthState());
  }
}