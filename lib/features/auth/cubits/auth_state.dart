import 'dart:convert';
import 'dart:convert' show utf8;

class AuthState {
  final bool isAuthenticated;
  final String? accessToken;
  final String? refreshToken;
  final String? fullName;
  final String? email;
  final String? message;
  final Map<String, dynamic>? userData;
  final String? userId;

  AuthState({
    this.isAuthenticated = false,
    this.accessToken,
    this.refreshToken,
    this.fullName,
    this.email,
    this.message,
    this.userData,
    this.userId,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    String? accessToken,
    String? refreshToken,
    String? fullName,
    String? message,
    String? email,
    Map<String, dynamic>? userData,
    String? userId,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      fullName: fullName ?? this.fullName,
      message: message ?? this.message,
      email: email ?? this.email,
      userData: userData ?? this.userData,
      userId: userId ?? this.userId,
    );
  }

  factory AuthState.fromJson(Map<String, dynamic> json) {
    String? token = json['accessToken'];
    if (token != null) {
      final parts = token.split('.');
      if (parts.length == 3) {
        final payload = parts[1];
        final normalized = base64Url.normalize(payload);
        final payloadMap = jsonDecode(utf8.decode(base64Url.decode(normalized)));
        
        return AuthState(
          isAuthenticated: true,
          accessToken: token,
          refreshToken: json['refreshToken'],
          fullName: payloadMap['FullName'] ?? json['fullName'] ?? 'User',
          email: payloadMap['email'] ?? json['email'] ?? '',
          userId: payloadMap['sub'],
        );
      }
    }
    
    return AuthState(
      isAuthenticated: true,
      accessToken: json['accessToken'],
      refreshToken: json['refreshToken'],
      fullName: json['fullName'] ?? 'User',
      email: json['email'] ?? '',
      userId: json['userId'],
    );
  }

  String? get token => accessToken;
}