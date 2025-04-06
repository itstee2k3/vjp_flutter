// home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_socket_io/features/auth/cubits/auth_cubit.dart';
import 'package:flutter_socket_io/features/auth/cubits/auth_state.dart';
import '../widgets/banner_widget.dart';
import '../widgets/search_widget.dart';
import '../widgets/company_vn_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String selectedFlag = 'vn'; // Default là cờ Việt Nam

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        return Material(
          color: Colors.white,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              // Banner có thể kéo giãn
              SliverToBoxAdapter(
                child: Container(
                  color: Colors.white,
                  child: const BannerWidget(),
                ),
              ),

              // Search bar
              SliverToBoxAdapter(
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(16),
                  child: SearchWidget(
                    onSearch: (value) {
                      // TODO: Implement search
                      print('Searching for: $value');
                    },
                    onFlagChanged: (flag) {
                      setState(() {
                        selectedFlag = flag;
                      });
                    },
                  ),
                ),
              ),

              // Danh sách công ty
              SliverToBoxAdapter(
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16).copyWith(bottom: 16),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Doanh nghiệp Việt Nam',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 16),
                      CompanyVnWidget(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
