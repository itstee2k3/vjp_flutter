import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:go_router/go_router.dart';

class BottomNavigation extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNavigation({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CurvedNavigationBar(
      index: currentIndex,
      height: 60.0,
      items: const <Widget>[
        Icon(Icons.home, size: 30, color: Colors.white),
        Icon(Icons.search, size: 30, color: Colors.white),
        Icon(Icons.event, size: 30, color: Colors.white),
        Icon(Icons.people, size: 30, color: Colors.white),
        Icon(Icons.help_outline, size: 30, color: Colors.white),
      ],
      color: Colors.red, // Màu nền của items
      buttonBackgroundColor: Colors.red, // Màu nền của item được chọn
      backgroundColor: Colors.transparent, // Màu nền phía sau navigation bar
      animationCurve: Curves.easeInOut,
      animationDuration: const Duration(milliseconds: 300),
      onTap: (index) {
        // Pop màn hình chi tiết nếu đang ở đó
        if (context.canPop()) {
          context.pop();
        }
        onTap(index);
      },
    );
  }
}