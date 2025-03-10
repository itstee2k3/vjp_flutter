import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_socket_io/features/auth/cubits/auth_cubit.dart';
import '../../features/auth/screens/auth_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/chat/cubits/chat_cubit.dart';
import '../../features/chat/screens/chat_screen.dart';
import '../../features/chat/cubits/chat_list_cubit.dart';
import '../../services/api/chat_api_service.dart';
import 'dart:convert';

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
        case '/chat':
          final token = authCubit.state.accessToken;
          final userId = authCubit.state.userId;

          if (token == null || token.isEmpty || userId == null) {
            return const AuthScreen();
          }

          print('Creating ChatApiService with userId: $userId'); // Debug log

          final chatApiService = ChatApiService(
            token: token,
            currentUserId: userId,
          );

          return MultiBlocProvider(
            providers: [
              BlocProvider<ChatListCubit>(
                create: (context) {
                  final authCubit = context.read<AuthCubit>();
                  return ChatListCubit(
                    chatApiService,
                    authCubit: authCubit,
                  )..loadUsers();
                },
              ),
            ],
            child: const ChatScreen(),
          );
        default:
          return const HomeScreen();
      }
    });
  }
}