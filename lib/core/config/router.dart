import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/cubits/auth_cubit.dart';
import '../../features/auth/screens/auth_screen.dart';
import '../../features/main/screens/main_screen.dart';
import '../../features/main/cubits/main_cubit.dart';
import '../../features/chat/screens/home_chat_screen.dart';
import '../../features/chat/screens/group/group_message_screen.dart';
import '../../features/chat/cubits/group/group_chat_cubit.dart';
import '../../features/chat/cubits/personal/personal_chat_list_cubit.dart';
import '../../features/chat/cubits/group/group_chat_list_cubit.dart';
import '../../services/api/chat_api_service.dart';
import '../../services/api/group_chat_api_service.dart';
import '../../features/chat/screens/group/group_list_screen.dart';
import '../../features/chat/screens/personal/personal_message_screen.dart';
import '../../features/chat/cubits/personal/personal_chat_cubit.dart';

final router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const MainScreen(),
    ),
    GoRoute(
      path: '/auth',
      builder: (context, state) => const AuthScreen(),
    ),
    GoRoute(
      path: '/chat',
      builder: (context, state) {
        final authCubit = context.read<AuthCubit>();
        final token = authCubit.state.accessToken;
        final userId = authCubit.state.userId;

        if (token == null || token.isEmpty || userId == null) {
          throw Exception('User not authenticated');
        }

        final chatApiService = ChatApiService(
          token: token,
          currentUserId: userId,
        );

        final groupChatApiService = GroupChatApiService(
          token: token,
          currentUserId: userId,
        );

        return MultiBlocProvider(
          providers: [
            BlocProvider<PersonalChatListCubit>(
              create: (context) => PersonalChatListCubit(
                chatApiService,
                authCubit: authCubit,
              )..loadUsers(),
            ),
            BlocProvider<GroupChatListCubit>(
              create: (context) => GroupChatListCubit(groupChatApiService)..loadGroups(),
            ),
          ],
          child: const HomeChatScreen(),
        );
      },
      routes: [
        GoRoute(
          path: 'personal/:userId',
          builder: (context, state) {
            final userId = state.pathParameters['userId']!;
            final username = state.uri.queryParameters['username'] ?? 'User';
            
            final authCubit = context.read<AuthCubit>();
            final token = authCubit.state.accessToken;
            final currentUserId = authCubit.state.userId;

            if (token == null || currentUserId == null) {
              throw Exception('User not authenticated');
            }

            return BlocProvider(
              create: (context) => PersonalChatCubit(
                ChatApiService(
                  token: token,
                  currentUserId: currentUserId,
                ),
                userId,
              ),
              child: PersonalMessageScreen(
                userId: userId,
                username: username,
              ),
            );
          },
        ),
        GoRoute(
          path: 'group/:groupId',
          builder: (context, state) {
            final groupId = int.parse(state.pathParameters['groupId']!);
            final groupName = state.uri.queryParameters['groupName'] ?? 'Group Chat';
            
            final authCubit = context.read<AuthCubit>();
            final token = authCubit.state.accessToken;
            final userId = authCubit.state.userId;

            if (token == null || userId == null) {
              throw Exception('User not authenticated');
            }

            return BlocProvider(
              create: (context) => GroupChatCubit(
                apiService: GroupChatApiService(
                  token: token,
                  currentUserId: userId,
                ),
                groupId: groupId,
              ),
              child: GroupMessageScreen(
                groupId: groupId,
                groupName: groupName,
              ),
            );
          },
        ),
      ],
    ),
    GoRoute(
      path: '/group-list',
      builder: (context, state) => const GroupListScreen(),
    ),
  ],
);