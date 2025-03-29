import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../data/models/user.dart';
import '../../../../data/models/message.dart';
import '../../../../services/api/chat_api_service.dart';
import '../../../auth/cubits/auth_cubit.dart';
import 'package:signalr_netcore/signalr_client.dart';

part 'personal_chat_list_state.dart';

class PersonalChatListCubit extends Cubit<PersonalChatListState> {
  final ChatApiService _chatService;
  final AuthCubit _authCubit;
  late StreamSubscription _authSubscription;
  Timer? _connectionCheckTimer;
  ChatApiService? _apiService;

  PersonalChatListCubit(this._chatService, {required AuthCubit authCubit})
      : _authCubit = authCubit,
        super(PersonalChatListState.initial()) {
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

  void initialize(ChatApiService apiService) {
    _apiService = apiService;
    loadUsers();
  }

  Future<void> loadUsers() async {
    if (_apiService == null) return;

    emit(state.copyWith(isLoading: true));
    try {
      final users = await _apiService!.getUsers();
      
      // Tải tin nhắn mới nhất cho mỗi người dùng
      final latestMessages = await _apiService!.getLatestMessagesForAllUsers(users);
      
      emit(state.copyWith(
        users: users,
        latestMessages: latestMessages,
        isLoading: false,
        isInitialized: true,
      ));
    } catch (e) {
      emit(state.copyWith(
        error: e.toString(),
        isLoading: false,
      ));
    }
  }

  void searchUsers(String query) {
    if (query.isEmpty) {
      loadUsers();
      return;
    }

    final filteredUsers = state.users
        .where((user) =>
            user.fullName.toLowerCase().contains(query.toLowerCase()) ||
            user.email.toLowerCase().contains(query.toLowerCase()))
        .toList();

    emit(state.copyWith(users: filteredUsers));
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