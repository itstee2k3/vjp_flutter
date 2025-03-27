import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../data/models/group_chat.dart';
import '../../cubits/group/group_chat_list_cubit.dart';

class GroupListScreen extends StatelessWidget {
  final Function(GroupChat) onGroupTap;

  const GroupListScreen({
    Key? key,
    required this.onGroupTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GroupChatListCubit, GroupChatListState>(
      builder: (context, state) {
        if (state.groups.isEmpty) {
          return const Center(
            child: Text('No groups yet'),
          );
        }

        return ListView.builder(
          itemCount: state.groups.length,
          itemBuilder: (context, index) {
            final group = state.groups[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundImage: group.avatarUrl != null && group.avatarUrl!.isNotEmpty
                    ? NetworkImage(group.avatarUrl!)  // Ảnh từ mạng nếu có
                    : AssetImage("assets/avatar_default/avatar_group_default.png") as ImageProvider, // Ảnh mặc định từ assets nếu không có URL
              ),
              title: Text(group.name),
              subtitle: Text(
                '${group.members.length} members',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              trailing: Text(
                '${group.createdAt.hour}:${group.createdAt.minute}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              onTap: () => onGroupTap(group),
            );
          },
        );
      },
    );
  }
} 