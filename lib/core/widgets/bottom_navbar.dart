import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../features/home/cubits/home_cubit.dart';
import '../../features/home/screens/home_screen.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;

  const BottomNavBar({
    Key? key,
    this.currentIndex = 0, // Mặc định là trang Home
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, state) {
        int currentIndex = state.index; // Kiểm tra state và lấy index

        return BottomNavigationBar(
          key: ValueKey(currentIndex), // Giúp Flutter biết widget cần cập nhật
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          elevation: 10,
          currentIndex: currentIndex,
          selectedItemColor: Colors.black,
          unselectedItemColor: Colors.black87,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
          onTap: (index) {
            if (index == 0) {
              if (ModalRoute.of(context)?.settings.name != '/') {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (context) => const HomeScreen(),
                    settings: const RouteSettings(name: '/'),
                  ),
                  (route) => false,
                );
              }
            } else if (index == 1) {
              _showModal(context, "Tìm kiếm", ["Tìm Doanh Nghiệp", "Tìm Chuyên Gia"]);
            } else if (index == 2) {
              _showModal(context, "Sự kiện", ["Sắp diễn ra", "Đã tổ chức", "Đăng ký sự kiện"]);
            } else if (index == 3) {
              _showModal(context, "Về Chúng Tôi", ["Giới thiệu", "Sứ mệnh", "Đội ngũ", "Liên hệ"]);
            } else if (index == 4) {
              _showModal(context, "FAQ", ["Câu hỏi thường gặp", "Hỗ trợ khách hàng"]);
            } else {
              context.read<HomeCubit>().changeTab(index);
            }
          },
          items: [
            _buildBottomNavigationBarItem(Icons.home, Icons.home_outlined, "Trang Chủ", currentIndex == 0),
            _buildBottomNavigationBarItem(Icons.search, Icons.search_outlined, "Tìm kiếm", currentIndex == 1),
            _buildBottomNavigationBarItem(Icons.event, Icons.event_outlined, "Sự kiện", currentIndex == 2),
            _buildBottomNavigationBarItem(Icons.info, Icons.info_outline, "Về Chúng Tôi", currentIndex == 3),
            _buildBottomNavigationBarItem(Icons.question_answer, Icons.question_answer_outlined, "FAQ", currentIndex == 4),
          ],
        );
      },
    );
  }

  BottomNavigationBarItem _buildBottomNavigationBarItem(
      IconData selectedIcon, IconData unselectedIcon, String label, bool isSelected) {
    return BottomNavigationBarItem(
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return ScaleTransition(scale: animation, child: child);
        },
        child: Icon(
          isSelected ? selectedIcon : unselectedIcon,
          key: ValueKey<bool>(isSelected),
        ),
      ),
      label: label,
    );
  }

  void _showModal(BuildContext context, String title, List<String> options) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Divider(),
              ...options.map((option) => ListTile(
                title: Text(option),
                onTap: () {
                  Navigator.pop(context);
                  print("Chọn: $option");
                },
              )),
            ],
          ),
        );
      },
    );
  }
}
