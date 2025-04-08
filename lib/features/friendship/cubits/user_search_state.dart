// user_search_state.dart
part of 'user_search_cubit.dart';

enum UserSearchStatus { initial, loading, success, failure, sendingRequest }

class UserSearchState extends Equatable {
  final UserSearchStatus status;
  final List<User> users;
  final String? errorMessage;
  final String? sendingRequestUserId;
  final String? errorSendingRequest;
  final bool successSendingRequest;

  const UserSearchState({
    this.status = UserSearchStatus.initial,
    this.users = const [],
    this.errorMessage,
    this.sendingRequestUserId,
    this.errorSendingRequest,
    this.successSendingRequest = false,
  });

  UserSearchState copyWith({
    UserSearchStatus? status,
    List<User>? users,
    String? errorMessage,
    ValueGetter<String?>? sendingRequestUserId,
    ValueGetter<String?>? errorSendingRequest,
    bool? successSendingRequest,
  }) {
    return UserSearchState(
      status: status ?? this.status,
      users: users ?? this.users,
      errorMessage: errorMessage ?? this.errorMessage,
      sendingRequestUserId: sendingRequestUserId != null ? sendingRequestUserId() : this.sendingRequestUserId,
      errorSendingRequest: errorSendingRequest != null ? errorSendingRequest() : this.errorSendingRequest,
      successSendingRequest: successSendingRequest ?? this.successSendingRequest,
    );
  }

  @override
  List<Object?> get props => [
        status,
        users,
        errorMessage,
        sendingRequestUserId,
        errorSendingRequest,
        successSendingRequest,
      ];
}
