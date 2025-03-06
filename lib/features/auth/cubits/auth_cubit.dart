import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/api/api_service.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final ApiService _apiService;
  static const String KEY_ACCESS_TOKEN = 'access_token';
  static const String KEY_REFRESH_TOKEN = 'refresh_token';

  AuthCubit(this._apiService) : super(AuthState()) {
    checkAuthStatus(); // Kiểm tra trạng thái auth khi khởi tạo
  }

  void loginSuccess(Map<String, dynamic> response) async {
    final newState = AuthState.fromJson(response);
    emit(newState);

    // Lưu token vào storage
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(KEY_ACCESS_TOKEN, response['accessToken']);
    await prefs.setString(KEY_REFRESH_TOKEN, response['refreshToken']);
  }

  void logout() async {
    // Xóa token khỏi storage
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(KEY_ACCESS_TOKEN);
    await prefs.remove(KEY_REFRESH_TOKEN);
    
    emit(AuthState()); // Reset state
  }

  Future<void> checkAuthStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString(KEY_ACCESS_TOKEN);
    final refreshToken = prefs.getString(KEY_REFRESH_TOKEN);

    if (accessToken != null && refreshToken != null) {
      // Tạo response map để parse thông tin từ token
      final response = {
        'success': true,
        'accessToken': accessToken,
        'refreshToken': refreshToken,
      };
      
      final newState = AuthState.fromJson(response);
      emit(newState);
    }
  }
}