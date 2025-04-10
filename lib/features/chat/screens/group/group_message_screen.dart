import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/api_config.dart';
import '../../cubits/group/group_chat_cubit.dart';
import '../../cubits/group/group_chat_state.dart';
import '../../widgets/chat_input_field.dart';
import '../../widgets/message_list.dart';
import '../../widgets/chat_header.dart';
import '../../mixins/chat_screen_mixin.dart';

class GroupMessageScreen extends StatefulWidget {
  final String groupName;
  final int groupId;

  const GroupMessageScreen({
    Key? key,
    required this.groupName,
    required this.groupId,
  }) : super(key: key);

  @override
  State<GroupMessageScreen> createState() => _GroupMessageScreenState();
}

class _GroupMessageScreenState extends State<GroupMessageScreen> with ChatScreenMixin, WidgetsBindingObserver {
  final FocusScopeNode _focusNode = FocusScopeNode();
  DateTime? _lastLeftTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    loadMessages(() => context.read<GroupChatCubit>().loadMessages());
    setupMessageStream(context.read<GroupChatCubit>().stream);
    _loadInitialGroupDetails();
  }

  void _loadInitialGroupDetails() {
    if (mounted) {
      context.read<GroupChatCubit>().reloadGroupDetails();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Called when the app lifecycle state changes (app goes to background/foreground)
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshGroupDetails();
    }
  }

  // Called when this route is pushed to the navigation stack
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Only refresh if we previously left the screen
    if (_lastLeftTime != null) {
      final timeSinceLeft = DateTime.now().difference(_lastLeftTime!);
      // Only refresh if more than 1 second has passed since leaving
      if (timeSinceLeft.inSeconds > 1) {
        _refreshGroupDetails();
      }
      _lastLeftTime = null; // Reset the timer
    }
  }

  // Keep track of when we navigate away
  void _recordNavigationAway() {
    _lastLeftTime = DateTime.now();
  }

  // Refresh the group details
  void _refreshGroupDetails() {
    if (mounted) {
      print('Refreshing group details');
      context.read<GroupChatCubit>().reloadGroupDetails();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FocusScope(
      node: _focusNode,
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: BlocBuilder<GroupChatCubit, GroupChatState>(
            builder: (context, state) {
              print('Building ChatHeader with name: ${state.groupName}, avatarUrl: ${state.avatarUrl}');
              return ChatHeader(
                title: state.groupName ?? widget.groupName,
                isGroup: true,
                avatarUrl: state.avatarUrl,
                onRefreshPressed: () {
                  print('Refreshing group messages');
                  context.read<GroupChatCubit>().resetAndReloadMessages();
                },
                onInfoPressed: () async {
                  // Record that we're navigating away to info screen
                  _recordNavigationAway();
                  // Await the result of navigation to the info screen (result not used directly here)
                  await context.push('/chat-info/${widget.groupId}?chatType=group');
                },
              );
            },
          ),
        ),
        body: BlocBuilder<GroupChatCubit, GroupChatState>(
          builder: (context, state) {
            if (state.isLoading) {
              return const Center(
                  child: CircularProgressIndicator());
            }

            return Column(
              children: [
                Expanded(
                  child: MessageList(
                    isGroupChat: true,
                    key: const ValueKey('group_message_list'),
                    messages: state.messages,
                    currentUserId: context.read<GroupChatCubit>().apiService.currentUserId ?? '',
                    scrollController: scrollController,
                    onRetryImage: () => context.read<GroupChatCubit>().retryImage(),
                    hasMoreMessages: state.hasMoreMessages,
                    isLoadingMore: state.isLoadingMore,
                    onLoadMore: () => context.read<GroupChatCubit>().loadMoreMessages(),
                    getUserInfo: (userId) => context.read<GroupChatCubit>().getUserInfo(userId),
                  ),
                ),
                ChatInputField(
                  controller: messageController,
                  onSend: () => sendMessage((content) => context.read<GroupChatCubit>().sendMessage(content)),
                  onImageSend: () => sendImage(() => context.read<GroupChatCubit>().sendImageMessage()),
                  isLoading: isLoading,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}