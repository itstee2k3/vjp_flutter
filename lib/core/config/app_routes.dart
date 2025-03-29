// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:flutter_socket_io/features/auth/cubits/auth_cubit.dart';
// import '../../features/auth/screens/auth_screen.dart';
// import '../../features/chat/cubits/personal/personal_chat_list_cubit.dart';
// import '../../features/home/screens/home_screen.dart';
// import '../../features/chat/screens/home_chat_screen.dart';
// import '../../services/api/chat_api_service.dart';
// import '../../features/chat/screens/group/group_message_screen.dart';
// import '../../features/chat/cubits/group/group_chat_cubit.dart';
// import '../../services/api/group_chat_api_service.dart';
//
// class AppRoutes {
//   static Route<dynamic> onGenerateRoute(RouteSettings settings) {
//     return MaterialPageRoute(builder: (context) {
//       final authCubit = context.read<AuthCubit>();
//
//       switch (settings.name) {
//         case '/':
//           return authCubit.state.isAuthenticated
//               ? const HomeScreen()
//               : const AuthScreen();
//         case '/home':
//           return const HomeScreen();
//         case '/chat':
//           final token = authCubit.state.accessToken;
//           final userId = authCubit.state.userId;
//
//           if (token == null || token.isEmpty || userId == null) {
//             return const AuthScreen();
//           }
//
//           print('Creating ChatApiService with userId: $userId'); // Debug log
//
//           final chatApiService = ChatApiService(
//             token: token,
//             currentUserId: userId,
//           );
//
//           return MultiBlocProvider(
//             providers: [
//               BlocProvider<PersonalChatListCubit>(
//                 create: (context) {
//                   final authCubit = context.read<AuthCubit>();
//                   return PersonalChatListCubit(
//                     chatApiService,
//                     authCubit: authCubit,
//                   )..loadUsers();
//                 },
//               ),
//             ],
//             child: const HomeChatScreen(),
//           );
//         case '/group-message':
//           final token = authCubit.state.accessToken;
//           final userId = authCubit.state.userId;
//           final args = settings.arguments as Map<String, dynamic>;
//           final groupId = int.parse(args['groupId'].toString());
//           final groupName = args['groupName'] as String;
//
//           if (token == null || token.isEmpty || userId == null) {
//             return const AuthScreen();
//           }
//
//           final groupChatApiService = GroupChatApiService(
//             token: token,
//             currentUserId: userId,
//           );
//
//           return BlocProvider(
//             create: (context) => GroupChatCubit(
//               apiService: groupChatApiService,
//               groupId: groupId,
//             )..loadMessages(),
//             child: GroupMessageScreen(
//               groupId: groupId,
//               groupName: groupName,
//             ),
//           );
//         default:
//           return const HomeScreen();
//       }
//     });
//   }
// }