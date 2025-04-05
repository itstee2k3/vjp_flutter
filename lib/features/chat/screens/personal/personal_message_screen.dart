import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubits/personal/personal_chat_cubit.dart';
import '../../cubits/personal/personal_chat_state.dart';
import '../../widgets/chat_input_field.dart';
import '../../widgets/message_list.dart';
import '../../widgets/chat_header.dart';
import '../../mixins/chat_screen_mixin.dart';

class PersonalMessageScreen extends StatefulWidget {
  final String username;
  final String userId;

  const PersonalMessageScreen({
    Key? key,
    required this.username,
    required this.userId,
  }) : super(key: key);

  @override
  State<PersonalMessageScreen> createState() => _PersonalMessageScreenState();
}

class _PersonalMessageScreenState extends State<PersonalMessageScreen> with ChatScreenMixin {

  @override
  void initState() {
    super.initState();
    loadMessages(() => context.read<PersonalChatCubit>().loadMessages());
    setupMessageStream(context.read<PersonalChatCubit>().stream);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: BlocBuilder<PersonalChatCubit, PersonalChatState>(
          builder: (context, state) {
            return ChatHeader(
              title: widget.username,
              onRefreshPressed: () {
                context.read<PersonalChatCubit>().resetAndReloadMessages();
              },
            );
          },
        ),
      ),
      body: BlocBuilder<PersonalChatCubit, PersonalChatState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(
                child: CircularProgressIndicator());
          }

          return Column(
            children: [
              Expanded(
                child: MessageList(
                  // isGroupChat: false,
                  messages: state.messages,
                  currentUserId: context.read<PersonalChatCubit>().chatService.currentUserId ?? '',
                  scrollController: scrollController,
                  onRetryImage: () => context.read<PersonalChatCubit>().retryImage(),
                  hasMoreMessages: state.hasMoreMessages,
                  isLoadingMore: state.isLoadingMore,
                  onLoadMore: () => context.read<PersonalChatCubit>().loadMoreMessages(),
                ),
              ),
              ChatInputField(
                controller: messageController,
                onSend: () => sendMessage((content) => context.read<PersonalChatCubit>().sendMessage(content)),
                onImageSend: () => sendImage(() => context.read<PersonalChatCubit>().sendImage()),
                isLoading: isLoading,
              ),
            ],
          );
        },
      ),
    );
  }
}
