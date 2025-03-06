// home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/widgets/bottom_navbar.dart';
import '../../../core/widgets/top_navbar.dart';
import '../cubits/home_cubit.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider<HomeCubit>(
      create: (context) => HomeCubit(), // Provide Cubit to the widget tree
      child: const Scaffold(
        appBar: TopNavBar(),
        body: Center(child: Text("Chào mừng đến với ứng dụng!")),
        bottomNavigationBar: BottomNavBar(), // BottomNavBar sử dụng HomeCubit
      ),
    );
  }
}
