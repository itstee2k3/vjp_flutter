import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubits/user_search_cubit.dart';
import '../../../data/models/user.dart';
import '../../../data/models/enums/friendship_status.dart';
import '../../../services/api/friendship_api_service.dart'; // Cần để gọi send request trực tiếp (hoặc qua Cubit)
import 'package:dio/dio.dart'; // Tạm thời để tạo service
import '../../auth/cubits/auth_cubit.dart'; // Để lấy token
import 'package:go_router/go_router.dart'; // Import GoRouter

class UserSearchScreen extends StatefulWidget {
  const UserSearchScreen({Key? key}) : super(key: key);

  @override
  State<UserSearchScreen> createState() => _UserSearchScreenState();
}

class _UserSearchScreenState extends State<UserSearchScreen> {
  final _searchController = TextEditingController();
  
  // Lấy instance FriendshipApiService từ context (được cung cấp bởi router)
  FriendshipApiService get _friendshipService => context.read<FriendshipApiService>();
  // Lấy UserSearchCubit từ context
  UserSearchCubit get _searchCubit => context.read<UserSearchCubit>();

  // Hàm xử lý gửi yêu cầu kết bạn (Gọi qua Cubit để quản lý state)
  void _sendRequest(String receiverId) {
    // Gọi hàm trong Cubit để xử lý logic và cập nhật state
    _searchCubit.sendFriendRequest(receiverId);
    // Cubit sẽ tự xử lý hiển thị lỗi/thành công qua state
  }

  // Hàm xử lý chấp nhận yêu cầu (Ví dụ - Cần có Cubit tương ứng)
  void _acceptRequest(int friendshipId) {
    // TODO: Gọi hàm accept trong FriendRequestCubit
    print("Chấp nhận yêu cầu ID: $friendshipId"); // Placeholder
    // Ví dụ: context.read<FriendRequestCubit>().acceptRequest(friendshipId);
    // Cập nhật lại trạng thái user trong search cubit
    // Hoặc điều hướng đi đâu đó
  }

  // Hàm xử lý từ chối yêu cầu (Ví dụ - Cần có Cubit tương ứng)
  void _rejectRequest(int friendshipId) {
    // TODO: Gọi hàm reject trong FriendRequestCubit
    print("Từ chối yêu cầu ID: $friendshipId"); // Placeholder
    // Ví dụ: context.read<FriendRequestCubit>().rejectRequest(friendshipId);
    // Cập nhật lại trạng thái user trong search cubit
  }

  // Hàm xử lý hủy yêu cầu đã gửi (TODO)
  void _cancelRequest(String userId) {
    // TODO: Implement cancel friend request logic in Cubit/Service
    print("Hủy yêu cầu kết bạn với ID: $userId");
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Chức năng hủy yêu cầu chưa được cài đặt.')),
    );
  }

   // Hàm xử lý hủy kết bạn (TODO)
  void _unfriend(String friendId) {
     // TODO: Implement unfriend logic in FriendListCubit/Service
    print("Hủy kết bạn với ID: $friendId");
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Chức năng hủy kết bạn chưa được cài đặt.')),
    );
    // Có thể gọi: context.read<FriendListCubit>().unfriend(friendId);
    // Sau đó cập nhật lại state trong search cubit
    _searchCubit.updateUserStatus(friendId, FriendshipStatus.none); 
  }


  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Tìm kiếm bạn bè...',
            border: InputBorder.none,
            suffixIcon: IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                if (_searchController.text.trim().isNotEmpty) {
                  _searchCubit.searchUsers(_searchController.text.trim());
                }
              },
            ),
          ),
          onSubmitted: (query) {
            if (query.trim().isNotEmpty) {
              _searchCubit.searchUsers(query.trim());
            }
          },
          autofocus: true,
        ),
      ),
      body: BlocConsumer<UserSearchCubit, UserSearchState>(
        listener: (context, state) {
          // Lắng nghe các thay đổi state (ví dụ: lỗi gửi yêu cầu)
          if (state.errorSendingRequest != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Lỗi: ${state.errorSendingRequest}'), backgroundColor: Colors.red),
            );
            _searchCubit.clearSendRequestError(); // Xóa lỗi sau khi hiển thị
          }
           if (state.successSendingRequest) {
             ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Đã gửi yêu cầu thành công!'), backgroundColor: Colors.green),
            );
             _searchCubit.clearSendRequestSuccess(); // Xóa trạng thái thành công
          }
        },
        builder: (context, state) {
          if (state.status == UserSearchStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state.status == UserSearchStatus.failure) {
            return Center(child: Text('Lỗi tìm kiếm: ${state.errorMessage}'));
          } else if (state.status == UserSearchStatus.success && state.users.isEmpty) {
            return const Center(child: Text('Không tìm thấy người dùng nào khớp.'));
          } else if (state.status == UserSearchStatus.success) {
            return ListView.builder(
              itemCount: state.users.length,
              itemBuilder: (context, index) {
                final user = state.users[index];
                // Tối ưu: Lấy trạng thái loading riêng cho từng user nếu cần
                final isSendingRequest = state.sendingRequestUserId == user.id;
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: (user.avatarUrl != null && user.avatarUrl!.isNotEmpty)
                        ? NetworkImage(user.avatarUrl!)
                        : const AssetImage("assets/avatar_default/avatar_default.png") as ImageProvider,
                  ),
                  title: Text(user.fullName),
                  subtitle: Text(user.email),
                  trailing: _buildActionButton(context, user, isSendingRequest),
                );
              },
            );
          } else { // initial
            return const Center(child: Text('Nhập tên hoặc email để tìm kiếm.'));
          }
        },
      ),
    );
  }

  // Cập nhật _buildActionButton để sử dụng isRequestSentByCurrentUser
  Widget _buildActionButton(BuildContext context, User user, bool isSendingRequest) {
    // Nếu đang gửi yêu cầu cho user này, hiển thị loading
    if (isSendingRequest) {
      return const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2));
    }

    switch (user.friendshipStatus) {
      case FriendshipStatus.none:
      case FriendshipStatus.rejected:
      case FriendshipStatus.blocked:
        return ElevatedButton(
          onPressed: () => _sendRequest(user.id),
          child: const Text('Kết bạn'),
          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
        );

      case FriendshipStatus.pendingSent: // Xử lý pendingSent
        // Đã gửi yêu cầu đi -> Hiển thị nút "Đã gửi" hoặc "Hủy"
        return OutlinedButton(
           onPressed: () => _cancelRequest(user.id), // TODO: Implement cancel request
          child: const Text('Đã gửi'),
          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
        );

      case FriendshipStatus.pendingReceived: // Xử lý pendingReceived
        // Nhận được yêu cầu từ người này -> Hiển thị "Phản hồi"
        return ElevatedButton(
          onPressed: () {
            context.push('/friend-requests');
          },
          child: const Text('Phản hồi'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
        );

      case FriendshipStatus.accepted:
        // Đã là bạn bè -> Hiển thị "Bạn bè" hoặc nút "Hủy kết bạn"
        return OutlinedButton(
          onPressed: () => _unfriend(user.id), // TODO: Implement unfriend
          child: const Text('Bạn bè'),
           style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.green),
            foregroundColor: Colors.green,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
        );

      default:
        return const SizedBox.shrink(); // Trường hợp không xác định
    }
  }
}