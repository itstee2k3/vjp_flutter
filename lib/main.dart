import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_socket_io/services/api/chat_api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'features/auth/cubits/auth_cubit.dart';
import 'features/chat/cubits/chat_list_cubit.dart';
import 'services/api/api_service.dart';
import 'core/config/app_routes.dart';
import 'features/auth/cubits/sign_in/sign_in_cubit.dart';
import 'features/home/cubits/home_cubit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final apiService = ApiService();

  runApp(MyApp(
    prefs: prefs,
    apiService: apiService,
  ));
}


class MyApp extends StatelessWidget {
  final SharedPreferences prefs;
  final ApiService apiService;

  const MyApp({
    super.key,
    required this.prefs,
    required this.apiService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => AuthCubit(
            prefs: prefs,
            apiService: apiService,
          )..checkAuthStatus(),
        ),
        BlocProvider(
          create: (context) {
            final authCubit = context.read<AuthCubit>();
            return ChatListCubit(
              ChatApiService(
                token: authCubit.state.accessToken,
                currentUserId: authCubit.state.userId,
              ),
              authCubit: authCubit,
            );
          },
        ),
        BlocProvider(
          create: (context) => HomeCubit(),
        ),
      ],
      child: MaterialApp(
        title: 'Flutter Socket.IO',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        initialRoute: '/home',
        onGenerateRoute: AppRoutes.onGenerateRoute,
      ),
    );
  }
}
