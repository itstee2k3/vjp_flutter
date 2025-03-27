part of 'personal_chat_list_cubit.dart';

class PersonalChatListState extends Equatable {
  final List<User> users;
  final bool isLoading;
  final String? error;
  final bool isInitialized;
  final bool isSocketConnected;

  const PersonalChatListState({
    required this.users,
    required this.isLoading,
    this.error,
    required this.isInitialized,
    this.isSocketConnected = false,
  });

  factory PersonalChatListState.initial() {
    return const PersonalChatListState(
      users: [],
      isLoading: false,
      error: null,
      isInitialized: false,
      isSocketConnected: false,
    );
  }

  PersonalChatListState copyWith({
    List<User>? users,
    bool? isLoading,
    String? error,
    bool? isInitialized,
    bool? isSocketConnected,
  }) {
    return PersonalChatListState(
      users: users ?? this.users,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      isInitialized: isInitialized ?? this.isInitialized,
      isSocketConnected: isSocketConnected ?? this.isSocketConnected,
    );
  }

  @override
  List<Object?> get props => [users, isLoading, error, isInitialized, isSocketConnected];
} 