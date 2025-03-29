import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/auth/cubits/auth_cubit.dart';
import '../../features/auth/cubits/auth_state.dart' as auth;
import '../../features/auth/screens/auth_screen.dart';

class TopNavigation extends StatelessWidget implements PreferredSizeWidget {
  final bool isLoggedIn;
  final String? fullName;
  final VoidCallback? onLogout;
  final bool showBackButton;
  final Widget? leading;

  const TopNavigation({
    Key? key,
    this.isLoggedIn = false,
    this.fullName,
    this.onLogout,
    this.showBackButton = false,
    this.leading,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool canPop = Navigator.of(context).canPop();

    return BlocSelector<AuthCubit, auth.AuthState, _AuthUIState>(
      selector: (state) => _AuthUIState(
        isAuthenticated: state.isAuthenticated,
        accessToken: state.accessToken,
        fullName: state.fullName,
      ),
      builder: (context, authState) {
        return AppBar(
          leading: leading ?? (canPop ? BackButton(
            onPressed: () => Navigator.of(context).pop(),
          ) : null),
          automaticallyImplyLeading: false,
          backgroundColor: Colors.yellow,
          elevation: 1,
          toolbarHeight: 60,
          title: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                if (showBackButton)
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black87),
                    onPressed: () => Navigator.pop(context),
                  ),
                _buildLogo(),
                const Spacer(),
                _buildUserActions(context, authState),
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

  Widget _buildUserActions(BuildContext context, _AuthUIState state) {
    return Row(
      children: [
        _buildLanguageSelector(),
        const SizedBox(width: 16),
        if (state.isAuthenticated && state.accessToken != null) ...[
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
            },
          ),
        ] else
          _buildActionButton(
            title: "Đăng Nhập",
            color: Colors.red,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AuthScreen()),
            ),
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
            child: Row(
              children: [
                Image.network(
                  'https://vjp-connect.com/images/logo2.png',
                  width: 24,
                  height: 24,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(Icons.flag, color: Colors.red);
                  },
                ),
                SizedBox(width: 8),
                Text('Tiếng Việt'),
              ],
            ),
          ),
          PopupMenuItem<String>(
            value: 'en',
            child: Row(
              children: [
                Image.network(
                  'https://vjp-connect.com/images/logo3.png',
                  width: 24,
                  height: 24,
                ),
                SizedBox(width: 8),
                Text('Tiếng Anh'),
              ],
            ),
          ),
          PopupMenuItem<String>(
            value: 'ja',
            child: Row(
              children: [
                Image.network(
                  'https://vjp-connect.com/images/logo4.png',
                  width: 24,
                  height: 24,
                ),
                SizedBox(width: 8),
                Text('Tiếng Nhật'),
              ],
            ),
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
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _AuthUIState {
  final bool isAuthenticated;
  final String? accessToken;
  final String? fullName;

  _AuthUIState({
    required this.isAuthenticated,
    this.accessToken,
    this.fullName,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _AuthUIState &&
          runtimeType == other.runtimeType &&
          isAuthenticated == other.isAuthenticated &&
          accessToken == other.accessToken &&
          fullName == other.fullName;

  @override
  int get hashCode => Object.hash(isAuthenticated, accessToken, fullName);
}
