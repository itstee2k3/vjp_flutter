import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/user.dart';
import '../../../services/api/chat_api_service.dart';
import '../../../features/auth/cubits/auth_cubit.dart';
import 'package:signalr_netcore/signalr_client.dart';

// States
class ChatListState {
  final List<User> users;
  final bool isLoading;
  final String? error;
  final bool isSocketConnected;

  ChatListState({
    this.users = const [],
    this.isLoading = false,
    this.error,
    this.isSocketConnected = false,
  });

  ChatListState copyWith({
    List<User>? users,
    bool? isLoading,
    String? error,
    bool? isSocketConnected,
  }) {
    return ChatListState(
      users: users ?? this.users,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isSocketConnected: isSocketConnected ?? this.isSocketConnected,
    );
  }
}

// Cubit
class ChatListCubit extends Cubit<ChatListState> {
  ChatApiService _chatService;
  final AuthCubit authCubit;
  late StreamSubscription _authSubscription;
  Timer? _connectionCheckTimer;

  ChatListCubit(this._chatService, {required this.authCubit}) : super(ChatListState()) {
    print('ChatListCubit initialized');
    
    // Đăng ký lắng nghe sự kiện đăng nhập/đăng xuất
    _authSubscription = authCubit.stream.listen((authState) {
      if (authState.isAuthenticated && !state.isSocketConnected) {
        print('User authenticated, connecting SignalR');
        _chatService = ChatApiService(
          token: authState.accessToken,
          currentUserId: authState.userId,
        );
        
        // Kết nối SignalR
        _chatService.connect();
        emit(state.copyWith(isSocketConnected: true));
        
        // Tải danh sách người dùng
        loadUsers();
        
        // Bắt đầu kiểm tra kết nối định kỳ
        _startConnectionCheck();
      } else if (!authState.isAuthenticated && state.isSocketConnected) {
        print('User logged out, disconnecting SignalR');
        _chatService.disconnect();
        _stopConnectionCheck();
        emit(state.copyWith(
          isSocketConnected: false,
          users: [],
        ));
      }
    });
    
    // Kết nối ban đầu nếu đã xác thực
    if (authCubit.state.isAuthenticated) {
      print('User already authenticated, connecting SignalR');
      _chatService.connect();
      emit(state.copyWith(isSocketConnected: true));
      loadUsers();
      _startConnectionCheck();
    }
  }

  ChatApiService get chatService => _chatService;

  Future<void> loadUsers() async {
    try {
      emit(state.copyWith(isLoading: true));
      final users = await _chatService.getUsers();
      emit(state.copyWith(
        users: users,
        isLoading: false,
      ));
    } catch (e) {
      print('Error loading users: $e');
      emit(state.copyWith(
        error: e.toString(),
        isLoading: false,
      ));
    }
  }

  void filterUsers(String query) {
    if (query.isEmpty) {
      loadUsers();
      return;
    }

    final filteredUsers = state.users.where((user) {
      return user.fullName.toLowerCase().contains(query.toLowerCase()) ||
             user.email.toLowerCase().contains(query.toLowerCase());
    }).toList();

    emit(state.copyWith(users: filteredUsers));
  }

  void reconnectSignalR() {
    print('Manually reconnecting SignalR');
    _chatService.disconnect();
    _chatService.connect();
    emit(state.copyWith(isSocketConnected: true));
  }

  void _startConnectionCheck() {
    _connectionCheckTimer?.cancel();
    _connectionCheckTimer = Timer.periodic(Duration(seconds: 30), (timer) async {
      if (_chatService.hubConnection.state != HubConnectionState.Connected) {
        print('Periodic check: SignalR not connected, reconnecting...');
        await _chatService.connect();
        emit(state.copyWith(isSocketConnected: _chatService.hubConnection.state == HubConnectionState.Connected));
      }
    });
  }

  void _stopConnectionCheck() {
    _connectionCheckTimer?.cancel();
    _connectionCheckTimer = null;
  }

  @override
  Future<void> close() {
    _authSubscription.cancel();
    _stopConnectionCheck();
    _chatService.disconnect();
    return super.close();
  }
} 