import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_socket_io/services/api/chat_api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'features/auth/cubits/auth_cubit.dart';
import 'features/auth/cubits/auth_state.dart';
import 'features/chat/cubits/chat_list_cubit.dart';
import 'services/api/api_service.dart';
import 'core/config/app_routes.dart';
import 'features/home/cubits/home_cubit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'features/main/cubits/main_cubit.dart';
import 'features/main/screens/main_screen.dart';

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
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<ApiService>.value(value: apiService),
      ],
      child: MultiBlocProvider(
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
          BlocProvider(
            create: (context) => MainCubit(),
          ),
        ],
        child: MaterialApp(
          title: 'VJP Connect',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            primarySwatch: Colors.blue,
            textTheme: GoogleFonts.robotoTextTheme(
              Theme.of(context).textTheme,
            ),
            iconTheme: const IconThemeData(
              color: Colors.black87,
              size: 24.0,
            ),
            appBarTheme: const AppBarTheme(
              iconTheme: IconThemeData(
                color: Colors.white,
                size: 24.0,
              ),
            ),
            bottomNavigationBarTheme: const BottomNavigationBarThemeData(
              selectedItemColor: Colors.blue,
              unselectedItemColor: Colors.grey,
              selectedIconTheme: IconThemeData(size: 24.0),
              unselectedIconTheme: IconThemeData(size: 24.0),
            ),
          ),
          home: const MainScreen(),
          showPerformanceOverlay: false,
        ),
      ),
    );
  }
}
