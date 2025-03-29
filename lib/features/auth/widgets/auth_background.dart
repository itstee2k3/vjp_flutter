// auth_background.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

class AuthBackground extends StatelessWidget {
  final bool isRegistering;
  final VoidCallback onToggleAuthMode;

  const AuthBackground({
    Key? key,
    required this.isRegistering,
    required this.onToggleAuthMode,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Xác định padding dựa trên platform
    double topPadding = 0;
    if (isRegistering) {
      if (kIsWeb || Platform.isAndroid) {
        topPadding = 150;
      } else if (Platform.isIOS) {
        topPadding = 50;
      }
    }

    return AnimatedPositioned(
      duration: Duration(milliseconds: 300),
      curve: Curves.easeOut,
      bottom: isRegistering ? 565 : -50,
      left: 0,
      right: 0,
      height: 400,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isRegistering
                ? [Colors.orangeAccent, Colors.redAccent] // Màu đỏ khi đăng ký
                : [Colors.redAccent, Colors.pinkAccent], // Màu xanh khi đăng nhập
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(20),
            bottom: Radius.circular(20),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.only(top: topPadding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                isRegistering ? "Chào Mừng!" : "Hello!",
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              SizedBox(height: 10),
              Text(
                isRegistering
                    ? "Hãy điền thông tin để tạo tài khoản mới."
                    : "Nếu chưa có tài khoản, vui lòng nhấn 'Đăng Ký'.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white),
              ),
              SizedBox(height: 20),
              OutlinedButton(
                onPressed: onToggleAuthMode,
                style: OutlinedButton.styleFrom(side: BorderSide(color: Colors.white)),
                child: Text(
                  isRegistering ? "ĐĂNG NHẬP" : "ĐĂNG KÝ",
                  style: TextStyle(fontSize: 16, color: Colors.white)
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}