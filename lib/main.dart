import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_socket_io/features/auth/cubits/auth_cubit.dart';
import 'package:flutter_socket_io/features/chat/cubits/group/group_chat_list_cubit.dart';
import 'package:flutter_socket_io/services/api/group_chat_api_service.dart';
import 'package:flutter_socket_io/services/api/api_service.dart';
import 'package:flutter_socket_io/features/main/cubits/main_cubit.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/config/router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('vi', null); // hoặc 'en', 'ja', v.v.

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
          BlocProvider<AuthCubit>(
            create: (context) => AuthCubit(
              prefs: prefs,
              apiService: context.read<ApiService>(),
            ),
          ),
          BlocProvider<MainCubit>(
            create: (context) => MainCubit(),
          ),
        ],
        child: Builder(
          builder: (context) {
            return MaterialApp.router(
              title: 'VJP Connect',
              debugShowCheckedModeBanner: false,
              theme: ThemeData(
                primarySwatch: Colors.blue,
                useMaterial3: true,
              ),
              routerConfig: router,
            );
          },
        ),
      ),
    );
  }
}
