// user_search_cubit.dart
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart'; // Import ValueGetter
import '../../../data/models/enums/friendship_status.dart';
import '../../../data/models/user.dart';
import '../../../services/api/friendship_api_service.dart'; // Import service

part 'user_search_state.dart';

class UserSearchCubit extends Cubit<UserSearchState> {
  final FriendshipApiService _friendshipService;

  UserSearchCubit(this._friendshipService) : super(const UserSearchState());

  Future<void> searchUsers(String query) async {
    if (query.trim().isEmpty) {
      emit(state.copyWith(status: UserSearchStatus.initial, users: []));
      return;
    }
    emit(state.copyWith(status: UserSearchStatus.loading));
    try {
      final users = await _friendshipService.searchUsers(query);
      emit(state.copyWith(status: UserSearchStatus.success, users: users));
    } catch (e) {
      emit(state.copyWith(status: UserSearchStatus.failure, errorMessage: e.toString()));
    }
  }

  // Phương thức gửi yêu cầu kết bạn
  Future<void> sendFriendRequest(String receiverId) async {
    // Đánh dấu là đang gửi cho user này
    emit(state.copyWith(sendingRequestUserId: () => receiverId, errorSendingRequest: () => null, successSendingRequest: false));
    try {
      await _friendshipService.sendFriendRequest(receiverId);
      // Cập nhật trạng thái user trong list thành pendingSent
      final updatedUsers = state.users.map((user) {
        if (user.id == receiverId) {
          // Sử dụng trạng thái đúng là pendingSent
          return user.copyWith(friendshipStatus: FriendshipStatus.pendingSent, isRequestSentByCurrentUser: true);
        }
        return user;
      }).toList();
      // Emit trạng thái thành công và cập nhật list user
      emit(state.copyWith(
        users: updatedUsers,
        sendingRequestUserId: () => null, // Xóa ID đang gửi
        successSendingRequest: true,
      ));
    } catch (e) {
      // Emit trạng thái lỗi
      emit(state.copyWith(
        sendingRequestUserId: () => null, // Xóa ID đang gửi
        errorSendingRequest: () => e.toString(),
      ));
    }
  }

  // Phương thức để xóa lỗi gửi yêu cầu (sau khi đã hiển thị)
  void clearSendRequestError() {
    emit(state.copyWith(errorSendingRequest: () => null));
  }

  // Phương thức để xóa trạng thái gửi thành công (sau khi đã hiển thị)
  void clearSendRequestSuccess() {
    emit(state.copyWith(successSendingRequest: false));
  }

  // Giữ lại phương thức này nếu cần cập nhật từ bên ngoài (ví dụ: sau khi chấp nhận/từ chối từ màn hình khác)
  void updateUserStatus(String userId, FriendshipStatus newStatus, {bool? isRequestSent}) {
    final updatedUsers = state.users.map((user) {
      if (user.id == userId) {
        return user.copyWith(friendshipStatus: newStatus, isRequestSentByCurrentUser: isRequestSent);
      }
      return user;
    }).toList();
    emit(state.copyWith(users: updatedUsers));
  }
}