import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../services/api/chat_api_service.dart';
import '../../../services/api/group_chat_api_service.dart';
import '../../../data/models/user.dart';
import '../../../data/models/group_chat.dart';
import '../../auth/cubits/auth_cubit.dart';
import '../cubits/personal/personal_chat_list_cubit.dart';
import '../cubits/group/group_chat_list_cubit.dart';
import 'personal/personal_list_screen.dart';
import 'group/group_list_screen.dart';
import '../cubits/personal/personal_chat_cubit.dart';
import '../cubits/group/group_chat_cubit.dart';
import 'personal/personal_message_screen.dart';
import 'group/group_chat_screen.dart';

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
        context.read<GroupChatListCubit>().loadGroups(groupChatService);
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

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (context) => PersonalChatCubit(
            ChatApiService(
              token: token,
              currentUserId: currentUserId,
            ),
            selectedUser.id,
          ),
          child: PersonalMessageScreen(
            username: selectedUser.fullName,
            userId: selectedUser.id,
          ),
        ),
      ),
    );
  }

  void _handleGroupTap(BuildContext context, GroupChat group) async {
    if (!await _checkAuthAndGetToken(context)) return;

    final authCubit = context.read<AuthCubit>();
    final token = authCubit.state.accessToken;
    final currentUserId = authCubit.state.userId;

    if (token == null || currentUserId == null) return;

    if (!context.mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (context) => GroupChatCubit(
            apiService: GroupChatApiService(
              token: token,
              currentUserId: currentUserId,
            ),
            groupId: group.id,
          ),
          child: GroupChatScreen(
            groupName: group.name,
            groupId: group.id,
          ),
        ),
      ),
    );
  }

  void _showCreateGroupDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final nameController = TextEditingController();
        final descriptionController = TextEditingController();

        return AlertDialog(
          title: const Text('Create New Group'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Group Name',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final name = nameController.text.trim();
                final description = descriptionController.text.trim();
                if (name.isNotEmpty) {
                  context.read<GroupChatListCubit>().createGroup(name, description);
                  Navigator.pop(context);
                }
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
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

              return PersonalListScreen(
                onMessageTap: (user) {
                  _handleUserTap(context, user);
                },
              );
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

              return GroupListScreen(
                onGroupTap: (group) {
                  _handleGroupTap(context, group);
                },
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_tabController.index == 0) {
            // Show new chat dialog
          } else {
            _showCreateGroupDialog();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
} 