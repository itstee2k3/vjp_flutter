import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../data/models/user.dart';
import '../../cubits/personal/personal_chat_list_cubit.dart';

class PersonalListScreen extends StatelessWidget {
  final Function(User) onMessageTap;

  const PersonalListScreen({
    Key? key,
    required this.onMessageTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PersonalChatListCubit, PersonalChatListState>(
      builder: (context, state) {
        if (state.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.error != null) {
          return Center(child: Text(state.error!));
        }

        return ListView.builder(
          itemCount: state.users.length,
          itemBuilder: (context, index) {
            final user = state.users[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundImage: user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                    ? NetworkImage(user.avatarUrl!)
                    : AssetImage("assets/avatar_default/avatar_default.png") as ImageProvider,
              ),
              title: Text(
                user.fullName,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              subtitle: Text(
                user.email,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey[600]),
              ),
              trailing: const Text(
                "ONLINE",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.green,
                ),
              ),
              onTap: () => onMessageTap(user),
            );
          },
        );
      },
    );
  }
} 