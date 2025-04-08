import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../cubits/friend_list_cubit.dart';
import '../../../data/models/friend.dart';
import '../cubits/friend_list_state.dart'; // Import model

class FriendListScreen extends StatelessWidget {
  const FriendListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final friendListCubit = context.read<FriendListCubit>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bạn bè'),
      ),
      body: BlocConsumer<FriendListCubit, FriendListState>(
        listener: (context, state) {
          if (state.status == FriendListStatus.failure && state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage!), backgroundColor: Colors.red),
            );
          }
        },
        builder: (context, state) {
          if (state.status == FriendListStatus.loading && state.friends.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          } else if (state.status == FriendListStatus.failure && state.friends.isEmpty) {
            return Center(child: Text('Lỗi tải danh sách bạn bè: ${state.errorMessage}'));
          } else if (state.friends.isEmpty) {
            return const Center(child: Text('Chưa có bạn bè nào. Hãy tìm kiếm và kết bạn!'));
          }

          return RefreshIndicator(
            onRefresh: () => friendListCubit.loadFriends(),
            child: ListView.builder(
              itemCount: state.friends.length,
              itemBuilder: (context, index) {
                final friend = state.friends[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: (friend.friendAvatarUrl != null && friend.friendAvatarUrl!.isNotEmpty)
                        ? NetworkImage(friend.friendAvatarUrl!)
                        : const AssetImage("assets/avatar_default/avatar_default.png") as ImageProvider,
                  ),
                  title: Text(friend.friendFullName),
                  // subtitle: Text(friend.isOnline ?? false ? 'Online' : 'Offline'), // Hiển thị trạng thái online nếu có
                  trailing: IconButton(
                    icon: const Icon(Icons.more_horiz),
                    onPressed: () {
                      // Hiển thị menu context (ví dụ: hủy kết bạn, xem profile)
                      _showFriendMenu(context, friendListCubit, friend);
                    },
                  ),
                  onTap: () {
                    // Điều hướng đến màn hình chat với người bạn này
                    // context.push('/chat/personal/${friend.friendId}?username=${Uri.encodeComponent(friend.friendFullName)}');
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _showFriendMenu(BuildContext context, FriendListCubit cubit, Friend friend) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.chat_bubble_outline),
                title: const Text('Nhắn tin'),
                onTap: () {
                  Navigator.pop(context); // Đóng bottom sheet
                  // Điều hướng đến màn hình chat
                  context.push('/chat/personal/${friend.friendId}?username=${Uri.encodeComponent(friend.friendFullName)}');
                },
              ),
              ListTile(
                  leading: const Icon(Icons.person_remove_outlined, color: Colors.red),
                  title: const Text('Hủy kết bạn', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(context); // Đóng bottom sheet
                    // Xác nhận trước khi hủy
                    showDialog(
                      context: context,
                      builder: (BuildContext dialogContext) {
                        return AlertDialog(
                          title: const Text('Xác nhận hủy kết bạn'),
                          content: Text('Bạn có chắc muốn hủy kết bạn với ${friend.friendFullName}?'),
                          actions: <Widget>[
                            TextButton(
                              child: const Text('Không'),
                              onPressed: () {
                                Navigator.of(dialogContext).pop();
                              },
                            ),
                            TextButton(
                              child: const Text('Hủy kết bạn', style: TextStyle(color: Colors.red)),
                              onPressed: () {
                                Navigator.of(dialogContext).pop();
                                cubit.unfriend(friend.friendId); // Gọi cubit để hủy
                              },
                            ),
                          ],
                        );
                      },
                    );
                  }),
            ],
          ),
        );
      },
    );
  }
}