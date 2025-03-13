import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/widgets/bottom_nav.dart';
import '../../about/screens/about_screen.dart';
import '../../event/screens/event_screen.dart';
import '../../home/screens/home_screen.dart';
import '../../faq/screens/faq_screen.dart';
import '../../search/screens/search_screen.dart';
import '../cubits/main_cubit.dart';
import '../../../core/widgets/top_nav.dart';
import '../widgets/main_bottom_navigation.dart';
import '../widgets/chat_fab.dart';

class MainScreen extends StatelessWidget {
  final Widget? child;

  const MainScreen({
    Key? key,
    this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MainCubit, MainState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: const PreferredSize(
            preferredSize: Size.fromHeight(kToolbarHeight),
            child: TopNavigation(),
          ),
          body: child ?? _buildBody(state.currentIndex),
          bottomNavigationBar: BottomNavigation(
            currentIndex: state.currentIndex,
            onTap: (index) => context.read<MainCubit>().changeTab(index),
          ),
          floatingActionButton: const ChatFAB(),
        );
      },
    );
  }

  Widget _buildBody(int index) {
    switch (index) {
      case 0:
        return const HomeScreen();
      case 1:
        return const SearchScreen();
      case 2:
        return const EventScreen();
      case 3:
        return const AboutScreen();
      case 4:
        return const FAQScreen();
      default:
        return const HomeScreen();
    }
  }
}

