import 'package:bloc/bloc.dart';
import '../../../data/models/friend.dart'; // Import model Friend
import '../../../services/api/friendship_api_service.dart';
import 'friend_list_state.dart'; // Import service API

class FriendListCubit extends Cubit<FriendListState> {
  final FriendshipApiService _friendshipService;
  // Có thể inject thêm các stream hoặc service khác nếu cần cho SignalR

  FriendListCubit(this._friendshipService) : super(const FriendListState());

  // Phương thức để tải danh sách bạn bè từ API
  Future<void> loadFriends() async {
    // Chỉ tải lại nếu đang không ở trạng thái loading
    if (state.status == FriendListStatus.loading) return;

    emit(state.copyWith(status: FriendListStatus.loading, clearError: true)); // Bắt đầu loading, xóa lỗi cũ
    try {
      // Gọi API để lấy dữ liệu bạn bè (hiện đang trả về dynamic)
      final dynamicData = await _friendshipService.getFriends();

      // Map dữ liệu dynamic nhận được sang List<Friend>
      // Quan trọng: Cần đảm bảo API trả về đúng cấu trúc JSON mà Friend.fromJson mong đợi
      final friends = (dynamicData as List)
          .map((json) => Friend.fromJson(json as Map<String, dynamic>))
          .toList();

      // Emit trạng thái thành công với danh sách bạn bè đã lấy được
      emit(state.copyWith(status: FriendListStatus.success, friends: friends));
    } catch (e) {
      // Emit trạng thái thất bại nếu có lỗi xảy ra
      emit(state.copyWith(status: FriendListStatus.failure, errorMessage: e.toString()));
    }
  }

  // Phương thức để hủy kết bạn
  Future<void> unfriend(String friendId) async {
    // Lấy friendshipId từ state hiện tại (cần Friend model có friendshipId)
    final friendshipToRemove = state.friends.firstWhere(
            (f) => f.friendId == friendId,
        orElse: () => throw Exception("Friend not found in current state")); // Hoặc xử lý nhẹ nhàng hơn

    // Tạo danh sách bạn bè mới (loại bỏ người vừa hủy) để cập nhật UI ngay lập tức (Optimistic Update)
    final optimisticFriends = state.friends.where((f) => f.friendId != friendId).toList();
    emit(state.copyWith(friends: optimisticFriends, status: FriendListStatus.success)); // Cập nhật UI trước

    try {
      // Gọi API để thực hiện hủy kết bạn trên server
      await _friendshipService.unfriend(friendId);
      // Nếu thành công, state đã được cập nhật ở trên, không cần làm gì thêm
      print('Unfriended $friendId successfully.');
    } catch (e) {
      // Nếu API thất bại, khôi phục lại danh sách bạn bè ban đầu và báo lỗi
      print('Failed to unfriend $friendId: $e');
      // Có thể emit lại state cũ hoặc chỉ báo lỗi
      emit(state.copyWith(
        // friends: state.friends, // Có thể khôi phục state cũ nếu muốn
          status: FriendListStatus.failure,
          errorMessage: 'Failed to unfriend: ${e.toString()}'));
      // Tải lại danh sách bạn bè để đảm bảo đồng bộ
      await loadFriends();
    }
  }

  // --- (Optional) Methods for SignalR updates ---

  // Phương thức để xóa bạn bè khỏi danh sách khi nhận được thông báo SignalR
  void friendRemovedBySignalR(String removedFriendActorId, int friendshipId) {
    // Kiểm tra xem người thực hiện có phải là user hiện tại không (tránh xóa 2 lần)
    // Cần có userId hiện tại ở đây, có thể lấy từ AuthCubit hoặc inject vào
    // final currentUserId = ...;
    // if (removedFriendActorId == currentUserId) return;

    print('Processing FriendshipRemoved notification for ID: $friendshipId');
    final updatedFriends = state.friends.where((f) => f.friendshipId != friendshipId).toList();
    if (updatedFriends.length < state.friends.length) {
      emit(state.copyWith(friends: updatedFriends));
      print('Friend removed from list via SignalR.');
    }
  }

  // Phương thức để thêm bạn mới vào danh sách khi nhận được thông báo SignalR
  void newFriendAddedBySignalR(Friend newFriend) {
    print('Processing FriendRequestAccepted notification for friend ID: ${newFriend.friendId}');
    // Kiểm tra xem bạn này đã tồn tại trong danh sách chưa
    if (!state.friends.any((f) => f.friendId == newFriend.friendId)) {
      emit(state.copyWith(friends: [newFriend, ...state.friends])); // Thêm vào đầu danh sách
      print('New friend added to list via SignalR.');
    }
  }
}