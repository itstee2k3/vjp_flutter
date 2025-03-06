import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_socket_io/features/auth/cubits/auth_cubit.dart';
import '../../features/auth/screens/auth_screen.dart';
import '../../features/home/screens/home_screen.dart';

class AppRoutes {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    return MaterialPageRoute(builder: (context) {      
      final authCubit = context.read<AuthCubit>();

      switch (settings.name) {
        case '/':
          return authCubit.state.isAuthenticated 
              ? const HomeScreen() 
              : const AuthScreen();
        case '/home':
          return const HomeScreen();
        default:
          return const HomeScreen();
      }
    });
  }
}