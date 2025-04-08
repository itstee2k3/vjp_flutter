// friend_request_cubit.dart
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../data/models/friend_request.dart'; // Import model
import '../../../services/api/friendship_api_service.dart';

part 'friend_request_state.dart';

class FriendRequestCubit extends Cubit<FriendRequestState> {
  final FriendshipApiService _friendshipService;

  FriendRequestCubit(this._friendshipService) : super(const FriendRequestState());

  Future<void> loadPendingRequests() async {
    emit(state.copyWith(status: FriendRequestStatus.loading));
    try {
      final dynamicData = await _friendshipService.getPendingRequests();
      // Cần map dynamicData sang List<FriendRequest>
      final requests = (dynamicData as List)
          .map((json) => FriendRequest.fromJson(json as Map<String, dynamic>))
          .toList();
      emit(state.copyWith(status: FriendRequestStatus.success, requests: requests));
    } catch (e) {
      emit(state.copyWith(status: FriendRequestStatus.failure, errorMessage: e.toString()));
    }
  }

  Future<void> acceptRequest(int friendshipId) async {
    emit(state.copyWith(processingIds: {...state.processingIds, friendshipId.toString()}));
    try {
      await _friendshipService.acceptRequest(friendshipId);
      // Xóa yêu cầu khỏi danh sách sau khi chấp nhận thành công
      final updatedRequests = state.requests.where((req) => req.friendshipId != friendshipId).toList();
      emit(state.copyWith(
        requests: updatedRequests,
        processingIds: {...state.processingIds}..remove(friendshipId.toString()),
      ));
      // Có thể emit thêm event thành công để UI hiển thị thông báo
    } catch (e) {
      emit(state.copyWith(
        errorMessage: 'Failed to accept request: $e', // Có thể hiển thị lỗi cụ thể
        processingIds: {...state.processingIds}..remove(friendshipId.toString()),
      ));
    }
  }

  Future<void> rejectRequest(int friendshipId) async {
    emit(state.copyWith(processingIds: {...state.processingIds, friendshipId.toString()}));
    try {
      await _friendshipService.rejectRequest(friendshipId);
      // Xóa yêu cầu khỏi danh sách
      final updatedRequests = state.requests.where((req) => req.friendshipId != friendshipId).toList();
      emit(state.copyWith(
        requests: updatedRequests,
        processingIds: {...state.processingIds}..remove(friendshipId.toString()),
      ));
    } catch (e) {
      emit(state.copyWith(
        errorMessage: 'Failed to reject request: $e',
        processingIds: {...state.processingIds}..remove(friendshipId.toString()),
      ));
    }
  }

  // (Nâng cao) Phương thức để thêm yêu cầu mới từ SignalR
  void addReceivedRequest(FriendRequest request) {
    // Kiểm tra trùng lặp nếu cần
    if (!state.requests.any((r) => r.friendshipId == request.friendshipId)) {
      emit(state.copyWith(requests: [request, ...state.requests]));
    }
  }
}
