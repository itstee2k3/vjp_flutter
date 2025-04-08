import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_socket_io/features/chat/widgets/create_group_form.dart';
import '../../../services/api/chat_api_service.dart';
import '../../../services/api/group_chat_api_service.dart';
import '../../../data/models/user.dart';
import '../../../data/models/group_chat.dart';
import '../../auth/cubits/auth_cubit.dart';
import '../cubits/personal/personal_chat_list_cubit.dart';
import '../cubits/group/group_chat_list_cubit.dart';
import '../cubits/group/group_chat_list_state.dart';
import 'personal/personal_list_screen.dart';
import 'group/group_list_screen.dart';
import '../cubits/personal/personal_chat_cubit.dart';
import '../cubits/group/group_chat_cubit.dart';
import 'personal/personal_message_screen.dart';
import 'group/group_message_screen.dart';
import 'package:go_router/go_router.dart';

class HomeChatScreen extends StatefulWidget {
  const HomeChatScreen({Key? key}) : super(key: key);

  @override
  State<HomeChatScreen> createState() => _HomeChatScreenState();
}

class _HomeChatScreenState extends State<HomeChatScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initCubits();
  }

  void _initCubits() {
    final authCubit = context.read<AuthCubit>();
    final token = authCubit.state.accessToken;
    final currentUserId = authCubit.state.userId;

    print('Token (${token?.length ?? 0} chars): ${token != null ? token.substring(0, 20) + "..." : "null"}');
    print('CurrentUserId: $currentUserId');

    if (token != null && currentUserId != null) {
      // Initialize PersonalChatListCubit
      if (!context.read<PersonalChatListCubit>().state.isInitialized) {
        context.read<PersonalChatListCubit>().initialize(
          ChatApiService(
            token: token,
            currentUserId: currentUserId,
          ),
        );
      }

      // Initialize GroupChatListCubit
      final groupChatService = GroupChatApiService(
        token: token,
        currentUserId: currentUserId,
      );
      
      print('Loading groups with service...');
      if (context.read<GroupChatListCubit>().state.groups.isEmpty) {
        context.read<GroupChatListCubit>().loadGroups();
      }
    } else {
      print('Cannot initialize chat services: token or userId is null');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<bool> _checkAuthAndGetToken(BuildContext context) async {
    final authCubit = context.read<AuthCubit>();
    await authCubit.checkAuthStatus();
    
    final state = authCubit.state;
    if (!state.isAuthenticated || state.accessToken == null || state.userId == null) {
      if (!context.mounted) return false;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Phiên đăng nhập đã hết hạn')),
      );
      Navigator.pushReplacementNamed(context, '/');
      return false;
    }
    return true;
  }

  void _handleUserTap(BuildContext context, User selectedUser) async {
    if (!await _checkAuthAndGetToken(context)) return;

    final authCubit = context.read<AuthCubit>();
    final token = authCubit.state.accessToken;
    final currentUserId = authCubit.state.userId;

    if (token == null || currentUserId == null) return;

    if (!context.mounted) return;

    // Use go_router push
    context.push('/chat/personal/${selectedUser.id}?username=${Uri.encodeComponent(selectedUser.fullName)}');
  }

  void _handleGroupTap(BuildContext context, GroupChat group) async {
    if (!await _checkAuthAndGetToken(context)) return;

    final authCubit = context.read<AuthCubit>();
    final token = authCubit.state.accessToken;
    final currentUserId = authCubit.state.userId;

    if (token == null || currentUserId == null) return;

    if (!context.mounted) return;

    // Use go_router push
    context.push('/chat/group/${group.id}?groupName=${Uri.encodeComponent(group.name)}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_search_outlined),
            tooltip: 'Tìm bạn bè',
            onPressed: () {
              context.push('/search-users');
            },
          ),
          IconButton(
            icon: const Icon(Icons.people_outline),
            tooltip: 'Danh sách bạn bè',
            onPressed: () {
              context.push('/friends');
            },
          ),
          IconButton(
            icon: const Icon(Icons.group_add_outlined),
            tooltip: 'Yêu cầu kết bạn',
            onPressed: () {
              context.push('/friend-requests');
            },
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.black,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.black,
          tabs: const [
            Tab(text: 'Chats'),
            Tab(text: 'Groups'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Personal Chats Tab
          BlocBuilder<PersonalChatListCubit, PersonalChatListState>(
            builder: (context, state) {
              if (state.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state.error != null) {
                return Center(child: Text(state.error!));
              }

              return const PersonalListScreen();
            },
          ),
          // Group Chats Tab
          BlocBuilder<GroupChatListCubit, GroupChatListState>(
            builder: (context, state) {
              if (state.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state.error != null) {
                return Center(child: Text(state.error!));
              }

              return const GroupListScreen();
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => const CreateGroupForm(),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
} 