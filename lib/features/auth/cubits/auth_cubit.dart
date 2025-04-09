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
    final fullName = prefs.getString(KEY_FULL_NAME);
    final email = prefs.getString(KEY_EMAIL);

    print('Checking auth status...');
    print('Access token exists: ${accessToken != null}');
    print('Refresh token exists: ${refreshToken != null}');
    print('UserId exists: ${userId != null}');
    print('FullName exists: ${fullName != null}');

    if (accessToken != null && refreshToken != null) {
      // Kiểm tra token hết hạn
      if (_isTokenExpired(accessToken)) {
        print('Access token expired, attempting refresh...');
        // Thử refresh token
        try {
          final newTokens = await _apiService.refreshToken(refreshToken);
          if (newTokens['success']) {
            print('Token refresh successful');
            // Cập nhật token mới
            await prefs.setString(KEY_ACCESS_TOKEN, newTokens['accessToken']);
            await prefs.setString(KEY_REFRESH_TOKEN, newTokens['refreshToken']);
            
            emit(AuthState.fromJson(newTokens));
            return;
          } else {
            print('Token refresh failed');
          }
        } catch (e) {
          print('Error refreshing token: $e');
        }
        
        print('Logging out due to invalid tokens...');
        // Nếu refresh thất bại, logout
        await logout();
        return;
      }

      print('Token still valid, maintaining session');
      // Token còn hạn, emit state bình thường
      final response = {
        'success': true,
        'isAuthenticated': true,
        'accessToken': accessToken,
        'refreshToken': refreshToken,
        'userId': userId,
        'fullName': fullName,
        'email': email,
      };

      // print('Emitting auth state with response: $response');
      emit(AuthState.fromJson(response));
    } else {
      print('No tokens found, user not authenticated');
      emit(AuthState());
    }
  }

  bool _isTokenExpired(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return true;

      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final payloadMap = jsonDecode(utf8.decode(base64Url.decode(normalized)));
      
      final expiry = DateTime.fromMillisecondsSinceEpoch(payloadMap['exp'] * 1000);
      final isExpired = DateTime.now().isAfter(expiry);
      
      // print('Token expiry time: $expiry');
      // print('Current time: ${DateTime.now()}');
      // print('Is token expired: $isExpired');
      
      return isExpired;
    } catch (e) {
      print('Error checking token expiry: $e');
      return true;
    }
  }

  Future<void> loginSuccess(Map<String, dynamic> response) async {
    try {
      final accessToken = response['accessToken'];
      print('Saving token: $accessToken'); // Debug log

      // Parse token để lấy thông tin
      String? fullName = response['FullName'];
      String? email = response['email'];

      if (accessToken != null) {
        try {
          final parts = accessToken.split('.');
          if (parts.length == 3) {
            final payload = parts[1];
            final normalized = base64Url.normalize(payload);
            final payloadMap = jsonDecode(utf8.decode(base64Url.decode(normalized)));
            
            // print('Token payload in loginSuccess: $payloadMap');
            
            // Get fullName from token if not provided in response
            fullName = fullName ?? payloadMap['FullName'];
            
            // Get email from token if not provided in response
            email = email ?? 
                   payloadMap['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress'];
          }
        } catch (e) {
          print('Error parsing token: $e');
        }

        await prefs.setString(KEY_ACCESS_TOKEN, accessToken);
        if (fullName != null) {
          print('Saving fullName: $fullName');
          await prefs.setString(KEY_FULL_NAME, fullName);
        }
        if (email != null) {
          await prefs.setString(KEY_EMAIL, email);
        }
      }

      if (response['refreshToken'] != null) {
        await prefs.setString(KEY_REFRESH_TOKEN, response['refreshToken']);
      }
      
      // Tạo AuthState để trích xuất userId từ token
      final authState = AuthState.fromJson({
        ...response,
        'fullName': fullName,
        'email': email,
        'success': true,
        'isAuthenticated': true,
      });
      
      // Lưu userId nếu có
      if (authState.userId != null) {
        await prefs.setString(KEY_USER_ID, authState.userId!);
        print('Đã lưu userId: ${authState.userId}');
      }

      print('Emitting AuthState with fullName: ${authState.fullName}');
      emit(authState);
    } catch (e) {
      print('Error in loginSuccess: $e');
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