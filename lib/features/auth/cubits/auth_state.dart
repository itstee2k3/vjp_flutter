import 'dart:convert';
import 'dart:convert' show utf8;
import 'package:equatable/equatable.dart';

class AuthState extends Equatable {
  final bool isAuthenticated;
  final String? accessToken;
  final String? refreshToken;
  final String? fullName;
  final String? email;
  final String? message;
  final Map<String, dynamic>? userData;

  const AuthState({
    this.isAuthenticated = false,
    this.accessToken,
    this.refreshToken,
    this.fullName,
    this.email,
    this.message,
    this.userData,
  });

  @override
  List<Object?> get props => [isAuthenticated, accessToken, refreshToken, fullName, email, message, userData];

  AuthState copyWith({
    bool? isAuthenticated,
    String? accessToken,
    String? refreshToken,
    String? fullName,
    String? message,
    String? email,
    Map<String, dynamic>? userData,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      fullName: fullName ?? this.fullName,
      message: message ?? this.message,
      email: email ?? this.email,
      userData: userData ?? this.userData,
    );
  }

  factory AuthState.fromJson(Map<String, dynamic> json) {
    final token = json['accessToken'];
    if (token != null) {
      try {
        final parts = token.split('.');
        if (parts.length == 3) {
          final payload = parts[1];
          final normalized = base64Url.normalize(payload);
          final resp = utf8.decode(base64Url.decode(normalized));
          final payloadMap = jsonDecode(resp);
          
          return AuthState(
            isAuthenticated: true,
            accessToken: token,
            refreshToken: json['refreshToken'],
            fullName: payloadMap['FullName'] ?? json['fullName'] ?? 'User',
            email: payloadMap['email'] ?? json['email'] ?? '',
            userData: payloadMap,
          );
        }
      } catch (e) {
        print('Error parsing JWT: $e');
      }
    }
    
    return AuthState(
      isAuthenticated: json['success'] ?? false,
      accessToken: json['accessToken'],
      refreshToken: json['refreshToken'],
      fullName: json['fullName'] ?? 'User',
      email: json['email'] ?? '',
    );
  }
}