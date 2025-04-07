import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../features/auth/cubits/auth_cubit.dart';

class ChatFAB extends StatelessWidget {
  const ChatFAB({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    
    if (!authState.isAuthenticated) {
      return const SizedBox.shrink();
    }

    return FloatingActionButton(
      onPressed: () {
        context.push('/chat');
      },
      backgroundColor: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
        side: const BorderSide(
          color: Colors.black12,
          width: 0.5,
        ),
      ),
      child: const Icon(
        Icons.chat_bubble_outline,
        color: Colors.black87,
        size: 26,
      ),
    );
  }
}