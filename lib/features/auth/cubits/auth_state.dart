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
    // Extract userId and other info from token if not provided directly
    String? userId = json['userId'];
    String? fullName = json['fullName'];
    String? email = json['email'];
    bool isAuthenticated = json['isAuthenticated'] ?? false;

    if (json['accessToken'] != null) {
      try {
        final parts = json['accessToken'].split('.');
        if (parts.length == 3) {
          final payload = parts[1];
          final normalized = base64Url.normalize(payload);
          final payloadMap = jsonDecode(utf8.decode(base64Url.decode(normalized)));
          
          // print('Token payload: $payloadMap'); // Debug log để xem payload

          // Get userId from token if not provided
          userId = userId ?? 
                  payloadMap['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name'];
          
          // Get fullName from token if not provided
          fullName = fullName ?? 
                    payloadMap['FullName'] ??
                    'User';
          
          // Get email from token if not provided
          email = email ?? 
                  payloadMap['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress'];
                  
          // If we have a valid token, we are authenticated
          isAuthenticated = true;
        }
      } catch (e) {
        print('Error extracting data from token: $e');
      }
    }

    // print('Parsed AuthState - fullName: $fullName, userId: $userId, email: $email');

    return AuthState(
      isAuthenticated: isAuthenticated,
      accessToken: json['accessToken'],
      refreshToken: json['refreshToken'],
      fullName: fullName ?? 'User',
      email: email,
      userId: userId,
      message: json['message'],
    );
  }

  String? get token => accessToken;
}