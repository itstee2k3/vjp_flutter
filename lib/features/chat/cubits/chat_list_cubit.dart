import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/user.dart';
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
  final ChatApiService _chatService;
  final AuthCubit _authCubit;
  late StreamSubscription _authSubscription;
  Timer? _connectionCheckTimer;

  ChatListCubit(this._chatService, {required AuthCubit authCubit})
      : _authCubit = authCubit,
        super(ChatListState()) {
    print('ChatListCubit initialized');
    
    // Đăng ký lắng nghe sự kiện đăng nhập/đăng xuất
    _authSubscription = _authCubit.stream.listen((authState) {
      if (authState.isAuthenticated && !state.isSocketConnected) {
        print('User authenticated, connecting SignalR');
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
    if (_authCubit.state.isAuthenticated) {
      print('User already authenticated, connecting SignalR');
      _chatService.connect();
      emit(state.copyWith(isSocketConnected: true));
      loadUsers();
      _startConnectionCheck();
    }
  }

  Future<void> loadUsers() async {
    try {
      emit(state.copyWith(isLoading: true, error: null));
      
      // Kiểm tra và refresh token nếu cần
      await _authCubit.checkAuthStatus();
      
      // Lấy token mới sau khi refresh
      final currentToken = _authCubit.state.accessToken;
      if (currentToken == null) {
        throw Exception('Token không hợp lệ');
      }

      // Cập nhật token mới cho ChatService
      _chatService.updateToken(currentToken);

      final users = await _chatService.getUsers();
      if (users.isEmpty) {
        emit(state.copyWith(
          isLoading: false,
          error: 'Không tìm thấy người dùng nào',
        ));
        return;
      }

      emit(state.copyWith(
        users: users,
        isLoading: false,
        error: null,
      ));
    } catch (e) {
      print('Error loading users: $e');
      emit(state.copyWith(
        isLoading: false,
        error: 'Không thể tải danh sách người dùng: ${e.toString()}',
        users: [], // Clear users list on error
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