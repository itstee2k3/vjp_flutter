import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_socket_io/features/auth/cubits/auth_cubit.dart';
import 'package:flutter_socket_io/services/api/api_service.dart';

import 'core/config/app_routes.dart';
import 'features/auth/cubits/sign_in/sign_in_cubit.dart';
import 'features/home/cubits/home_cubit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final apiService = ApiService();
  
  runApp(MyApp(apiService: apiService));
}

class MyApp extends StatelessWidget {
  final ApiService apiService;
  
  const MyApp({
    Key? key,
    required this.apiService,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => AuthCubit(apiService),
        ),
        BlocProvider(
          create: (context) => SignInCubit(
            apiService,
            context.read<AuthCubit>(),
          ),
        ),
        BlocProvider(
          create: (_) => HomeCubit(),
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