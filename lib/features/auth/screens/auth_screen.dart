import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../services/api/api_service.dart';
import '../cubits/auth_cubit.dart';
import '../cubits/sign_in/sign_in_cubit.dart';
import '../cubits/sign_up/sign_up_cubit.dart';
import 'sign_in_form.dart';
import 'sign_up_form.dart';
import '../widgets/auth_background.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isRegistering = false;

  void _toggleAuthMode() {
    setState(() {
      _isRegistering = !_isRegistering;
    });
  }

  @override
  Widget build(BuildContext context) {
    final apiService = ApiService();
    final authCubit = context.read<AuthCubit>();

    return Scaffold(
      body: Stack(
        children: [
          AuthBackground(isRegistering: _isRegistering, onToggleAuthMode: _toggleAuthMode),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: _isRegistering
                  ? BlocProvider(
                      create: (context) => SignUpCubit(apiService),
                      child: const SignUpForm(),
                    )
                  : BlocProvider(
                      create: (context) => SignInCubit(apiService, authCubit),
                      child: const SignInForm(),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}