import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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

class _GroupMessageScreenState extends State<GroupMessageScreen> with ChatScreenMixin {
  final FocusScopeNode _focusNode = FocusScopeNode();

  @override
  void initState() {
    super.initState();
    loadMessages(() => context.read<GroupChatCubit>().loadMessages());
    setupMessageStream(context.read<GroupChatCubit>().stream);
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
              return ChatHeader(
                title: widget.groupName,
                isGroup: true,
                onRefreshPressed: () {
                  print('Refreshing group messages');
                  context.read<GroupChatCubit>().resetAndReloadMessages();
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
                    key: const ValueKey('group_message_list'),
                    messages: state.messages,
                    currentUserId: context.read<GroupChatCubit>().apiService.currentUserId ?? '',
                    scrollController: scrollController,
                    onRetryImage: () => context.read<GroupChatCubit>().retryImage(),
                    hasMoreMessages: state.hasMoreMessages,
                    isLoadingMore: state.isLoadingMore,
                    onLoadMore: () => context.read<GroupChatCubit>().loadMoreMessages(),
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