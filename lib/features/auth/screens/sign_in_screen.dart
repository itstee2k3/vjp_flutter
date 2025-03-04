import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_socket_io/providers/home.dart';
import 'package:flutter_socket_io/providers/login.dart';
import 'package:flutter_socket_io/features/home/home_screen.dart';
import 'package:provider/provider.dart';

import '../../home/home_cubit.dart';
import '../cubits/sign_in/sign_in_cubit.dart';
import '../cubits/sign_in/sign_in_state.dart';


class SignInScreen extends StatefulWidget {
  const SignInScreen({Key? key}) : super(key: key);

  @override
  State<SignInScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<SignInScreen> {
  final TextEditingController _usernameController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  _login() {
    final loginCubit = context.read<SignInCubit>();
    final username = _usernameController.text.trim();

    if (username.isNotEmpty) {
      loginCubit.clearError();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (_) => HomeCubit(username), // ✅ Truyền username vào HomeCubit
            child: HomeScreen(username: username),
          ),
        ),
      );
    } else {
      loginCubit.setErrorMessage('Username is required!');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              BlocBuilder<SignInCubit, SignInState>(
                builder: (_, state) {
                  if (state.errorMessage.isNotEmpty) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 30.0),
                      child: Card(
                        color: Colors.red,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            state.errorMessage,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    );
                  }
                  return Container();
                },
              ),
              Image.asset('assets/socket_icon.png'),
              const SizedBox(
                height: 5,
              ),
              Text(
                'Flutter Socket.IO',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(
                height: 40,
              ),
              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Who are you?',
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              ElevatedButton(
                onPressed: _login,
                child: const Text('Start Now'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
