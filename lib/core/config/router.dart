import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../data/sample_data/companies_data.dart';
import '../../features/auth/cubits/auth_cubit.dart';
import '../../features/auth/screens/auth_screen.dart';
import '../../features/friendship/cubits/friend_request_cubit.dart';
import '../../features/friendship/cubits/user_search_cubit.dart';
import '../../features/home/screens/company_detail_screen.dart';
import '../../features/main/screens/main_screen.dart';
import '../../features/main/cubits/main_cubit.dart';
import '../../features/chat/screens/home_chat_screen.dart';
import '../../features/chat/screens/group/group_message_screen.dart';
import '../../features/chat/cubits/group/group_chat_cubit.dart';
import '../../features/chat/cubits/personal/personal_chat_list_cubit.dart';
import '../../features/chat/cubits/group/group_chat_list_cubit.dart';
import '../../services/api/chat_api_service.dart';
import '../../services/api/friendship_api_service.dart';
import '../../services/api/group_chat_api_service.dart';
import '../../features/chat/screens/group/group_list_screen.dart';
import '../../features/chat/screens/personal/personal_message_screen.dart';
import '../../features/chat/cubits/personal/personal_chat_cubit.dart';
import '../../features/friendship/screens/user_search_screen.dart';
import '../../features/friendship/screens/friend_requests_screen.dart';
import '../../features/friendship/screens/friend_list_screen.dart';
import '../../features/friendship/cubits/friend_list_cubit.dart';
import '../../features/chat/cubits/group/group_info_cubit.dart';
import '../../core/config/api_config.dart';
import 'package:flutter_socket_io/features/chat/cubits/personal/personal_info_cubit.dart';
import 'package:flutter_socket_io/features/chat/screens/shared/chat_info_screen.dart';
import 'package:flutter_socket_io/features/chat/screens/shared/chat_media_screen.dart';
import 'package:flutter_socket_io/features/chat/cubits/shared/chat_media_cubit.dart';

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
              create: (context) => GroupChatListCubit(groupChatApiService),
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
      builder: (context, state) {
        // Check if GroupChatListCubit already exists in parent
        if (context.read<GroupChatListCubit>().state.groups.isEmpty) {
          context.read<GroupChatListCubit>().loadGroups();
        }
        return const GroupListScreen();
      },
    ),
    GoRoute(
      path: '/company/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        final company = sampleCompanies.firstWhere(
          (company) => company.id == id,
          orElse: () => sampleCompanies.first,
          );
        return CompanyDetailScreen(company: company);
      },
    ),
    GoRoute(
      path: '/search-users',
      builder: (context, state) {
        final authState = context.read<AuthCubit>().state;
        if (authState.accessToken == null) {
          return const Center(child: Text('Authentication required'));
        }
        final friendshipService = FriendshipApiService(dio: Dio(BaseOptions(baseUrl: ApiConfig.baseUrl)), token: authState.accessToken);

        return BlocProvider(
          create: (context) => UserSearchCubit(friendshipService),
          child: const UserSearchScreen(),
        );
      },
    ),
    GoRoute(
      path: '/friend-requests',
      builder: (context, state) {
        final authState = context.read<AuthCubit>().state;
         if (authState.accessToken == null) {
          return const Center(child: Text('Authentication required'));
        }
        final friendshipService = FriendshipApiService(dio: Dio(BaseOptions(baseUrl: ApiConfig.baseUrl)), token: authState.accessToken);

        return BlocProvider(
          create: (context) => FriendRequestCubit(friendshipService)..loadPendingRequests(),
          child: const FriendRequestsScreen(),
        );
      },
    ),
    GoRoute(
        path: '/friends',
        builder: (context, state) {
          final authState = context.read<AuthCubit>().state;
           if (authState.accessToken == null) {
            return const Center(child: Text('Authentication required'));
          }
          final friendshipService = FriendshipApiService(dio: Dio(BaseOptions(baseUrl: ApiConfig.baseUrl)), token: authState.accessToken);

          return BlocProvider(
            create: (context) => FriendListCubit(friendshipService)..loadFriends(),
            child: const FriendListScreen(),
          );
        }
    ),
    GoRoute(
      path: '/chat-info/:chatId',
      builder: (context, state) {
        final chatIdString = state.pathParameters['chatId'];
        final chatTypeString = state.uri.queryParameters['chatType'] ?? 'group'; 
        final chatType = chatTypeString == 'personal' ? ChatType.personal : ChatType.group;

        if (chatIdString == null) {
          return const Scaffold(body: Center(child: Text('Missing Chat ID')));
        }

        final authState = context.read<AuthCubit>().state;
        final token = authState.accessToken;
        final currentUserId = authState.userId;

        if (token == null || currentUserId == null) {
            return const Scaffold(body: Center(child: Text('User not authenticated')));
        }

        final chatApiService = ChatApiService(token: token, currentUserId: currentUserId);
        final groupChatApiService = GroupChatApiService(token: token, currentUserId: currentUserId);

        try {
          return BlocProvider<ChatMediaCubit>(
            create: (context) => ChatMediaCubit(
              chatIdString: chatIdString,
              chatType: chatType,
              chatApiService: chatApiService,
              groupChatApiService: groupChatApiService,
            ),
            child: Builder(
              builder: (mediaContext) {
                if (chatType == ChatType.group) {
                  final groupId = int.parse(chatIdString);
                  return BlocProvider<GroupInfoCubit>(
                    create: (context) => GroupInfoCubit(groupChatApiService, groupId)..loadGroupDetails(),
                    child: ChatInfoScreen(chatIdString: groupId.toString(), chatType: chatType),
                  );
                } else {
                  final personalUserId = chatIdString;
                  return BlocProvider<PersonalInfoCubit>(
                    create: (context) => PersonalInfoCubit(chatApiService, personalUserId),
                    child: ChatInfoScreen(chatIdString: personalUserId, chatType: chatType),
                  );
                }
              }
            ),
          );
        } catch (e) {
          return Scaffold(body: Center(child: Text('Invalid Chat ID format for type $chatTypeString: $chatIdString. Error: $e')));
        }
      },
    ),
    // New route for displaying chat media
    GoRoute(
      path: '/chat-media/:chatId',
      builder: (context, state) {
        final chatIdString = state.pathParameters['chatId'];
        final chatTypeString = state.uri.queryParameters['chatType'] ?? 'group'; // Default or error
        final chatType = chatTypeString == 'personal' ? ChatType.personal : ChatType.group;

        if (chatIdString == null) {
          return const Scaffold(body: Center(child: Text('Missing Chat ID')));
        }

        // Need Auth state to get services
        final authState = context.read<AuthCubit>().state;
        final token = authState.accessToken;
        final currentUserId = authState.userId;

        if (token == null || currentUserId == null) {
           return const Scaffold(body: Center(child: Text('User not authenticated')));
        }

        // Provide ChatMediaCubit here
        return BlocProvider(
          create: (_) => ChatMediaCubit(
              chatIdString: chatIdString,
              chatType: chatType,
              // Provide the necessary API services based on auth state
              chatApiService: ChatApiService(token: token, currentUserId: currentUserId),
              groupChatApiService: GroupChatApiService(token: token, currentUserId: currentUserId),
          ),
          child: ChatMediaScreen(
            chatIdString: chatIdString,
            chatTypeString: chatTypeString,
          ),
        );
      },
    ),
  ],
);