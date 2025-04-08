
import 'package:equatable/equatable.dart';

import '../../../data/models/friend.dart';

enum FriendListStatus { initial, loading, success, failure }

class FriendListState extends Equatable {
  final FriendListStatus status;
  final List<Friend> friends; // Danh sách bạn bè (sử dụng model Friend)
  final String? errorMessage;

  const FriendListState({
    this.status = FriendListStatus.initial,
    this.friends = const [],
    this.errorMessage,
  });

  // Hàm tiện ích để tạo bản sao của state với một số thay đổi
  FriendListState copyWith({
    FriendListStatus? status,
    List<Friend>? friends,
    String? errorMessage,
    bool clearError = false, // Thêm tùy chọn để xóa lỗi
  }) {
    return FriendListState(
      status: status ?? this.status,
      friends: friends ?? this.friends,
      // Nếu clearError là true thì đặt errorMessage là null, ngược lại giữ giá trị cũ hoặc cập nhật mới
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }

  // Các thuộc tính cần đưa vào để so sánh trạng thái (cho Equatable)
  @override
  List<Object?> get props => [status, friends, errorMessage];
}