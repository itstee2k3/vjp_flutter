import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/api_config.dart';
import '../../../../data/models/group_chat.dart';
import '../../../../data/models/message.dart';
import '../../cubits/group/group_chat_list_cubit.dart';
import '../../cubits/group/group_chat_list_state.dart';

class GroupListScreen extends StatefulWidget {
  const GroupListScreen({Key? key}) : super(key: key);

  @override
  State<GroupListScreen> createState() => _GroupListScreenState();
}

class _GroupListScreenState extends State<GroupListScreen> with WidgetsBindingObserver {
  DateTime? _lastLeftTime;
  bool _hasRefreshedGroups = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Only load groups if empty
    if (context.read<GroupChatListCubit>().state.groups.isEmpty) {
      context.read<GroupChatListCubit>().loadGroups();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshGroups();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initial load logic: Load groups only if the list is currently empty and not loading.
    if (!_hasRefreshedGroups) {
      _hasRefreshedGroups = true; 
      final cubit = context.read<GroupChatListCubit>();
      if (cubit.state.groups.isEmpty && !cubit.state.isLoading) {
        print('GroupListScreen: Initial load triggered in didChangeDependencies.');
        cubit.loadGroups();
      }
    }
  }

  void _refreshGroups() {
    // Refresh only if the widget is still mounted.
    if (mounted) {
      print('Refreshing group list triggered by _refreshGroups()');
      context.read<GroupChatListCubit>().loadGroups();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GroupChatListCubit, GroupChatListState>(
      builder: (context, state) {
        // Keep track of the current avatar URLs being displayed
        final Map<int, String?> currentAvatars = {}; 
        state.groups.forEach((group) => currentAvatars[group.id] = group.avatarUrl);

        if (state.isLoading && state.groups.isEmpty) { // Show loading only if groups are empty initially
          return const Center(child: CircularProgressIndicator());
        }

        if (state.error != null) {
          return Center(child: Text(state.error!));
        }

        if (state.groups.isEmpty) {
          return const Center(
            child: Text('Chưa có nhóm chat nào'),
          );
        }

        return WillPopScope(
          onWillPop: () {
            _lastLeftTime = DateTime.now();
            return Future.value(true);
          },
          child: ListView.builder(
            itemCount: state.groups.length,
            itemBuilder: (context, index) {
              final group = state.groups[index];
              // Construct the URL with cache buster
              final imageUrl = group.avatarUrl != null && group.avatarUrl!.isNotEmpty
                  ? '${ApiConfig.getFullImageUrl(group.avatarUrl)}?t=${DateTime.now().millisecondsSinceEpoch}'
                  : null;
              
              return ListTile(
                leading: CircleAvatar(
                  radius: 25,
                  backgroundImage: imageUrl != null
                      ? NetworkImage(imageUrl)
                      : AssetImage(ApiConfig.defaultGroupAvatar) as ImageProvider,
                  backgroundColor: Colors.grey[200],
                  // Use a key based on the group ID and the IMAGE URL to ensure rebuild on change
                  key: ValueKey('group-avatar-${group.id}-${imageUrl ?? "default"}'), 
                  onBackgroundImageError: (exception, stackTrace) {
                    print('❌ Error loading avatar in GroupListScreen for group ${group.id}: $exception');
                  },
                ),
                title: Text(
                  group.name,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: Text(
                  _getMessagePreview(group.lastMessage),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontStyle: group.lastMessage == null ? FontStyle.italic : FontStyle.normal,
                  ),
                ),
                trailing: group.lastMessage != null 
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _formatTime(group.lastMessageAt ?? DateTime.now()),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (group.lastMessage != null && !group.lastMessage!.isRead)
                          Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    )
                  : null,
                onTap: () {
                  _lastLeftTime = DateTime.now();
                  context.push('/chat/group/${group.id}?groupName=${Uri.encodeComponent(group.name)}');
                },
              );
            },
          ),
        );
      },
    );
  }
  
  String _getMessagePreview(Message? message) {
    if (message == null) {
      return 'Chưa có tin nhắn';
    }
    
    switch (message.type) {
      case MessageType.text:
        return message.content;
      case MessageType.image:
        return '🖼️ Hình ảnh';
      case MessageType.file:
        return '📎 Tệp tin';
      case MessageType.audio:
        return '🎵 Âm thanh';
      case MessageType.video:
        return '🎬 Video';
      default:
        return message.content;
    }
  }
  
  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(time.year, time.month, time.day);

    if (messageDate == today) {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } else if (messageDate == yesterday) {
      return 'Hôm qua';
    } else if (now.difference(time).inDays < 7) {
      return ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'][time.weekday - 1];
    } else {
      return '${time.day}/${time.month}/${time.year}';
    }
  }
}