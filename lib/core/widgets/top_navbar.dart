import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/auth/cubits/auth_cubit.dart';
import '../../features/auth/cubits/auth_state.dart' as auth;

class TopNavBar extends StatelessWidget implements PreferredSizeWidget {
  final bool isLoggedIn;
  final String? fullName;
  final VoidCallback? onLogout;

  const TopNavBar({
    Key? key,
    this.isLoggedIn = false,
    this.fullName,
    this.onLogout,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, auth.AuthState>(
      builder: (context, state) {
        return AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.yellow,
          elevation: 1,
          toolbarHeight: 60,
          title: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                _buildLogo(),
                const Spacer(),
                _buildUserActions(context, state),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLogo() {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Image.network(
        "https://vjp-connect.com/_next/static/media/logovjpc.8300dbca.png",
        height: 40,
        errorBuilder: (context, error, stackTrace) {
          return const Text(
            'VJP Connect',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          );
        },
      ),
    );
  }

  Widget _buildUserActions(BuildContext context, auth.AuthState state) {
    return Row(
      children: [
        _buildLanguageSelector(),
        const SizedBox(width: 16),
        if (state.isAuthenticated) ...[
          Text(
            state.fullName ?? 'User',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          const SizedBox(width: 16),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black87),
            onPressed: () {
              context.read<AuthCubit>().logout();
              Navigator.of(context).pushNamedAndRemoveUntil(
                '/',
                (route) => false,
              );
            },
          ),
        ] else
          _buildActionButton(
            title: "Đăng Nhập",
            color: Colors.red,
            onPressed: () => Navigator.pushNamed(context, '/'),
          ),
      ],
    );
  }

  Widget _buildLanguageSelector() {
    return PopupMenuButton<String>(
      tooltip: 'Chọn ngôn ngữ',
      icon: const Icon(Icons.language, color: Colors.black87),
      itemBuilder: (BuildContext context) {
        return [
          PopupMenuItem<String>(
            value: 'vi',
            child: const Text('Tiếng Việt'),
          ),
          PopupMenuItem<String>(
            value: 'en',
            child: const Text('Tiếng Anh'),
          ),
          PopupMenuItem<String>(
            value: 'ja',
            child: const Text('Tiếng Nhật'),
          ),
        ];
      },
      onSelected: (String value) {
        print('Đã chọn ngôn ngữ: $value');
      },
    );
  }

  Widget _buildActionButton({
    required String title,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: onPressed,
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(60);
}
