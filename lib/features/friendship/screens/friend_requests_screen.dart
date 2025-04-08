import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubits/friend_request_cubit.dart';
import '../../../data/models/friend_request.dart'; // Import model

class FriendRequestsScreen extends StatelessWidget {
  const FriendRequestsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final requestCubit = context.read<FriendRequestCubit>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Yêu cầu kết bạn'),
      ),
      body: BlocConsumer<FriendRequestCubit, FriendRequestState>(
        listener: (context, state) {
          // Hiển thị SnackBar nếu có lỗi (ngoài lỗi loading)
          if (state.status == FriendRequestStatus.failure && state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage!), backgroundColor: Colors.red),
            );
          }
        },
        builder: (context, state) {
          if (state.status == FriendRequestStatus.loading && state.requests.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          } else if (state.status == FriendRequestStatus.failure && state.requests.isEmpty) {
            return Center(child: Text('Lỗi tải yêu cầu: ${state.errorMessage}'));
          } else if (state.requests.isEmpty) {
            return const Center(child: Text('Không có yêu cầu kết bạn nào.'));
          }

          return RefreshIndicator(
            onRefresh: () => requestCubit.loadPendingRequests(),
            child: ListView.builder(
              itemCount: state.requests.length,
              itemBuilder: (context, index) {
                final request = state.requests[index];
                final isProcessing = state.processingIds.contains(request.friendshipId);
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: (request.requesterAvatarUrl != null && request.requesterAvatarUrl!.isNotEmpty)
                        ? NetworkImage(request.requesterAvatarUrl!)
                        : const AssetImage("assets/avatar_default/avatar_default.png") as ImageProvider,
                  ),
                  title: Text(request.requesterFullName),
                  subtitle: Text('Đã gửi lúc: ${request.requestedAt.toLocal()}'), // Định dạng thời gian nếu cần
                  trailing: isProcessing
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(
                        onPressed: () => requestCubit.rejectRequest(request.friendshipId),
                        child: const Text('Từ chối', style: TextStyle(color: Colors.red)),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => requestCubit.acceptRequest(request.friendshipId),
                        child: const Text('Chấp nhận'),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}