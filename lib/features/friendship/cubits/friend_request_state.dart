// friend_request_state.dart
part of 'friend_request_cubit.dart';

enum FriendRequestStatus { initial, loading, success, failure, processing }

class FriendRequestState extends Equatable {
  final FriendRequestStatus status;
  final List<FriendRequest> requests; // Sử dụng model FriendRequest đã tạo
  final String? errorMessage;
  final Set<String> processingIds; // Theo dõi ID đang xử lý (accept/reject)

  const FriendRequestState({
    this.status = FriendRequestStatus.initial,
    this.requests = const [],
    this.errorMessage,
    this.processingIds = const {},
  });

  FriendRequestState copyWith({
    FriendRequestStatus? status,
    List<FriendRequest>? requests,
    String? errorMessage,
    Set<String>? processingIds,
  }) {
    return FriendRequestState(
      status: status ?? this.status,
      requests: requests ?? this.requests,
      errorMessage: errorMessage ?? this.errorMessage,
      processingIds: processingIds ?? this.processingIds,
    );
  }

  @override
  List<Object?> get props => [status, requests, errorMessage, processingIds];
}