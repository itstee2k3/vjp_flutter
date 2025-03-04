import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../data/model/message.dart';
import 'home_cubit.dart';
import 'home_state.dart';

class HomeScreen extends StatelessWidget {
  final String username;
  HomeScreen({Key? key, required this.username}) : super(key: key);

  final TextEditingController _messageInputController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => HomeCubit(username),
      child: Scaffold(
        appBar: AppBar(title: const Text('Flutter Socket.IO')),
        body: Column(
          children: [
            Expanded(
              child: BlocBuilder<HomeCubit, HomeState>(
                builder: (context, state) {
                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    reverse: true, // Hiển thị tin nhắn mới ở cuối
                    itemBuilder: (context, index) {
                      final message = state.messages.reversed.toList()[index];
                      final isMe = message.senderUsername == username;

                      return Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Card(
                          color: isMe
                              ? Theme.of(context).primaryColorLight
                              : Colors.white,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: isMe
                                  ? CrossAxisAlignment.end
                                  : CrossAxisAlignment.start,
                              children: [
                                Text(message.message),
                                Text(
                                  DateFormat('hh:mm a').format(message.sentAt),
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                    separatorBuilder: (_, index) => const SizedBox(height: 5),
                    itemCount: state.messages.length,
                  );
                },
              ),
            ),
            Container(
              decoration: BoxDecoration(color: Colors.grey.shade200),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageInputController,
                        decoration: const InputDecoration(
                          hintText: 'Type your message here...',
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        if (_messageInputController.text.trim().isNotEmpty) {
                          context.read<HomeCubit>().sendMessage(
                            _messageInputController.text.trim(),
                            username,
                          );
                          _messageInputController.clear();
                        }
                      },
                      icon: const Icon(Icons.send),
                    )
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
