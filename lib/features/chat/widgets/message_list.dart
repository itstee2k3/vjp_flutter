import 'package:flutter/material.dart';
import '../../../data/models/message.dart';
import 'image_message_bubble.dart';
import 'text_message_bubble.dart';
import 'message_time.dart';

// Define BubblePosition enum
enum BubblePosition { single, first, middle, last }

class MessageList extends StatefulWidget {
  final List<Message> messages;
  final String currentUserId;
  final ScrollController scrollController;
  final VoidCallback? onRetryImage;
  final Function(Message)? onRetryImageWithMessage;
  final bool hasMoreMessages;
  final bool isLoadingMore;
  final VoidCallback? onLoadMore;
  final bool isGroupChat;
  final Function(String userId)? getUserInfo;

  const MessageList({
    Key? key,
    required this.messages,
    required this.currentUserId,
    required this.scrollController,
    this.onRetryImage,
    this.onRetryImageWithMessage,
    this.hasMoreMessages = false,
    this.isLoadingMore = false,
    this.onLoadMore,
    this.isGroupChat = false,
    this.getUserInfo,
  }) : super(key: key);

  @override
  State<MessageList> createState() => _MessageListState();
}

class _MessageListState extends State<MessageList> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final List<double> _messageAnimations = [];
  bool _isFirstLoad = true;
  int _previousMessageCount = 0;
  bool _isNearBottom = true;
  bool _isOverscrolling = false;
  double _overscrollProgress = 0.0;
  static const double _overscrollThreshold = 100.0;
  bool _shouldLoadMore = false;

  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_scrollListener);
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _initializeAnimations();
    _previousMessageCount = widget.messages.length;

    // Cuộn xuống dưới khi lần đầu load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.scrollController.hasClients && _isFirstLoad) {
        widget.scrollController.jumpTo(
          widget.scrollController.position.maxScrollExtent,
        );
        _isFirstLoad = false;
      }
    });
  }

  void _initializeAnimations() {
    _messageAnimations.clear();
    for (int i = 0; i < widget.messages.length; i++) {
      _messageAnimations.add(1.0);
    }
  }

  bool _checkIfNearBottom() {
    if (!widget.scrollController.hasClients) return true;

    final position = widget.scrollController.position;
    final maxScroll = position.maxScrollExtent;
    final currentScroll = position.pixels;

    return currentScroll >= maxScroll - 150;
  }

  void _handleOverscroll(ScrollNotification notification) {
    if (!widget.hasMoreMessages || widget.isLoadingMore) {
      // print('Cannot load more: hasMoreMessages=${widget.hasMoreMessages}, isLoadingMore=${widget.isLoadingMore}');
      return;
    }

    if (notification is ScrollUpdateNotification) {
      final position = notification.metrics;
      if (position.pixels < position.minScrollExtent) {
        final overscrollAmount = position.minScrollExtent - position.pixels;
        final progress = (overscrollAmount / _overscrollThreshold).clamp(0.0, 1.0);
        // print('Overscroll update: amount=$overscrollAmount, progress=$progress, threshold=$_overscrollThreshold');

        setState(() {
          _isOverscrolling = true;
          _overscrollProgress = progress;
          if (progress >= 1.0) {
            print('Setting shouldLoadMore to true (progress >= 1.0)');
            _shouldLoadMore = true;
          }
        });
      } else {
        // print('Resetting overscroll state but keeping shouldLoadMore=$_shouldLoadMore');
        setState(() {
          _isOverscrolling = false;
          _overscrollProgress = 0.0;
        });
      }
    } else if (notification is ScrollEndNotification) {
      // print('Scroll end: shouldLoadMore=$_shouldLoadMore, hasMoreMessages=${widget.hasMoreMessages}, isLoadingMore=${widget.isLoadingMore}');

      if (_shouldLoadMore && widget.hasMoreMessages && !widget.isLoadingMore) {
        print('Triggering load more messages...');
        widget.onLoadMore?.call();

        // Keep _shouldLoadMore true until loading completes
        setState(() {
          _isOverscrolling = false;
          _overscrollProgress = 0.0;
        });
      } else {
        print('Not loading more: shouldLoadMore=$_shouldLoadMore, hasMoreMessages=${widget.hasMoreMessages}, isLoadingMore=${widget.isLoadingMore}');

        setState(() {
          _isOverscrolling = false;
          _overscrollProgress = 0.0;
          _shouldLoadMore = false;
        });
      }
    }
  }

  void _scrollListener() {
    if (!widget.scrollController.hasClients) return;
    _isNearBottom = _checkIfNearBottom();
  }

  @override
  void didUpdateWidget(MessageList oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Reset _shouldLoadMore when loading completes
    if (oldWidget.isLoadingMore && !widget.isLoadingMore) {
      setState(() {
        _shouldLoadMore = false;
      });
    }

    // Xử lý tin nhắn mới
    if (widget.messages.length > _previousMessageCount &&
        (oldWidget.messages.isEmpty ||
         (oldWidget.messages.isNotEmpty && widget.messages.last.id != oldWidget.messages.last.id))) {
      final newMessagesCount = widget.messages.length - _previousMessageCount;
      print('New messages added: $newMessagesCount');
      print('Is near bottom: $_isNearBottom');

      // Chỉ tự động cuộn xuống nếu đang ở gần cuối
      if (_isNearBottom) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (widget.scrollController.hasClients) {
            widget.scrollController.animateTo(
              widget.scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }

      // Cập nhật animations cho tin nhắn mới
      while (_messageAnimations.length < widget.messages.length) {
        _messageAnimations.add(0.0);
      }

      // Animate tin nhắn mới
      for (int i = _previousMessageCount; i < widget.messages.length; i++) {
        Future.delayed(Duration(milliseconds: 50 * (i - _previousMessageCount)), () {
          if (mounted) {
            setState(() {
              _messageAnimations[i] = 1.0;
            });
          }
        });
      }
    }
    // Xử lý tin nhắn cũ (load more)
    else if (widget.messages.length > oldWidget.messages.length &&
        (oldWidget.messages.isEmpty ||
         (oldWidget.messages.isNotEmpty && widget.messages.first.id != oldWidget.messages.first.id))) {
      final newMessagesCount = widget.messages.length - oldWidget.messages.length;
      print('Old messages loaded: $newMessagesCount');

      // Make sure we have both a scroll controller and that it has attached to clients
      if (!widget.scrollController.hasClients) {
        print('ScrollController has no clients, skipping position adjustment');
        return;
      }

      // Store scroll metrics before layout changes
      final oldScrollPosition = widget.scrollController.position.pixels;
      final oldMaxExtent = widget.scrollController.position.maxScrollExtent;

      // We'll measure the content height difference in a post-frame callback

      // Thêm animations cho tin nhắn cũ - Initialize with opacity 1.0 directly
      for (int i = 0; i < newMessagesCount; i++) {
        _messageAnimations.insert(0, 1.0); // Set opacity to 1 immediately for old messages
      }
      
      // Estimate added height based on message type for better accuracy with images
      double calculatedEstimatedHeightDifference = 0;
      const double textHeightEstimate = 50.0; // Adjust based on your text bubble height + padding
      const double imageHeightEstimate = 250.0; // Adjust based on typical image bubble height + padding

      for (int i = 0; i < newMessagesCount; i++) {
        final message = widget.messages[i];
        if (message.type == MessageType.image) {
          calculatedEstimatedHeightDifference += imageHeightEstimate;
        } else { // Assuming other types (like text) use textHeightEstimate
          calculatedEstimatedHeightDifference += textHeightEstimate;
        }
      }
      print('Calculated estimated height difference: $calculatedEstimatedHeightDifference for $newMessagesCount items');

      // Maintain scroll position after loading older messages 
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!widget.scrollController.hasClients) {
          print('ScrollController has no clients, skipping position adjustment');
          return;
        }

        try {
          // Jump based on the calculated estimated height difference
          if (calculatedEstimatedHeightDifference > 0) {
            final targetPosition = oldScrollPosition + calculatedEstimatedHeightDifference;
            widget.scrollController.jumpTo(targetPosition);
            print('Adjusted scroll position based on calculated estimate to: $targetPosition');
          } else {
             print('No calculated estimated height difference, keeping original position: $oldScrollPosition');
             if (widget.scrollController.position.pixels != oldScrollPosition) {
                 widget.scrollController.jumpTo(oldScrollPosition);
             }
          }
          
        } catch (e) {
          print('Error adjusting scroll position based on calculated estimate: $e');
        }
      });
    }

    // Cập nhật số lượng tin nhắn
    _previousMessageCount = widget.messages.length;
  }

  // Helper function to check sender and time grouping
  bool _areMessagesInSameGroup(Message? m1, Message? m2) {
    if (m1 == null || m2 == null) return false;
    return m1.senderId == m2.senderId &&
        m1.sentAt.year == m2.sentAt.year &&
        m1.sentAt.month == m2.sentAt.month &&
        m1.sentAt.day == m2.sentAt.day &&
        m1.sentAt.hour == m2.sentAt.hour &&
        m1.sentAt.minute == m2.sentAt.minute;
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_scrollListener);
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification scrollInfo) {
        _handleOverscroll(scrollInfo);
        return true;
      },
      child: CustomScrollView(
        controller: widget.scrollController,
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          // Loading indicator
          SliverToBoxAdapter(
            child: _buildLoadingIndicator(),
          ),
          // Message list
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final message = widget.messages[index];
                final isMe = message.senderId == widget.currentUserId;

                // --- Grouping Logic --- 
                final bool isFirstMessage = index == 0;
                final bool isLastMessage = index == widget.messages.length - 1;

                final Message? prevMessage = isFirstMessage ? null : widget.messages[index - 1];
                final Message? nextMessage = isLastMessage ? null : widget.messages[index + 1];

                // Use helper function for grouping check
                final bool sameGroupAsPrevious = _areMessagesInSameGroup(prevMessage, message);
                final bool sameGroupAsNext = _areMessagesInSameGroup(message, nextMessage);

                BubblePosition bubblePosition;
                if (sameGroupAsPrevious && sameGroupAsNext) {
                  bubblePosition = BubblePosition.middle;
                } else if (sameGroupAsPrevious && !sameGroupAsNext) {
                  bubblePosition = BubblePosition.last;
                } else if (!sameGroupAsPrevious && sameGroupAsNext) {
                  bubblePosition = BubblePosition.first;
                } else { // !sameGroupAsPrevious && !sameGroupAsNext
                  bubblePosition = BubblePosition.single;
                }
                // --- End Grouping Logic ---

                // Determine if the timestamp should be shown (only for last/single messages IN A GROUP)
                bool showTimestamp = bubblePosition == BubblePosition.last || bubblePosition == BubblePosition.single;

                // Override: always show timestamp for the absolute last message in the list,
                // but ensure its bubble position reflects its potential group status accurately
                if (isLastMessage) {
                   showTimestamp = true;
                   // Recalculate position just for the last item if needed
                   if (sameGroupAsPrevious) {
                       bubblePosition = BubblePosition.last;
                   } else {
                       bubblePosition = BubblePosition.single;
                   }
                }

                // Determine spacing based on bubble position (should be correct now)
                double topMargin = (bubblePosition == BubblePosition.first || bubblePosition == BubblePosition.single) ? 8.0 : 1.0;
                double bottomMargin = showTimestamp ? 4.0 : 1.0; // Less space if timestamp isn't shown below, normal if it is
                if (bubblePosition == BubblePosition.last || bubblePosition == BubblePosition.single){
                  bottomMargin += 4.0; // Add extra space after last/single message before next group/timestamp
                }

                // Lấy thông tin người gửi nếu là chat nhóm và không phải người dùng hiện tại
                Map<String, dynamic>? senderInfo;
                if (widget.isGroupChat && !isMe && widget.getUserInfo != null) {
                  senderInfo = widget.getUserInfo!(message.senderId);
                }

                // Wrap the bubble and potential timestamp in a Column
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Column(
                    crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: topMargin), // Apply dynamic top margin
                      AnimatedOpacity(
                        opacity: _messageAnimations.length > index ? _messageAnimations[index] : 1.0,
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOut,
                        child: message.type == MessageType.image
                            ? ImageMessageBubble(
                                message: message,
                                isMe: isMe,
                                onRetry: widget.onRetryImage,
                                onRetryWithMessage: widget.onRetryImageWithMessage,
                                bubblePosition: bubblePosition, // Pass bubble position
                                showSenderInfo: widget.isGroupChat && !isMe, // Chỉ hiển thị thông tin người gửi trong chat nhóm
                                senderInfo: senderInfo,
                              )
                            : TextMessageBubble(
                                message: message,
                                isMe: isMe,
                                bubblePosition: bubblePosition, // Pass bubble position
                                showSenderInfo: widget.isGroupChat && !isMe, // Chỉ hiển thị thông tin người gửi trong chat nhóm
                                senderInfo: senderInfo,
                              ),
                      ),
                      // Conditionally display MessageTime outside the bubble
                      if (showTimestamp)
                        Padding(
                          padding: EdgeInsets.only(top: 4, bottom: bottomMargin - 4), // Adjust padding for timestamp
                          child: MessageTime(time: message.sentAt, isMe: isMe),
                        )
                      else
                         SizedBox(height: bottomMargin), // Apply bottom margin if no timestamp
                    ],
                  ),
                );
              },
              childCount: widget.messages.length,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    if (!widget.hasMoreMessages && !widget.isLoadingMore && !_isOverscrolling) {
      return const SizedBox.shrink();
    }

    // print('Building loading indicator: hasMoreMessages=${widget.hasMoreMessages}, isLoadingMore=${widget.isLoadingMore}, isOverscrolling=$_isOverscrolling, overscrollProgress=$_overscrollProgress');

    return SizedBox(
      height: 60,
      child: Center(
        child: widget.isLoadingMore
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Đang tải tin nhắn...',
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodySmall?.color,
                      fontSize: 12,
                    ),
                  ),
                ],
              )
            : _isOverscrolling
                ? SizedBox(
                    height: 44,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          height: 20 * _overscrollProgress,
                          child: Icon(
                            _overscrollProgress >= 1.0
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            color: Colors.grey,
                            size: 20 * (0.5 + _overscrollProgress),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _overscrollProgress >= 1.0
                              ? 'Thả để tải thêm tin nhắn'
                              : 'Kéo xuống để tải thêm tin nhắn',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                            fontWeight: _overscrollProgress >= 1.0
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
      ),
    );
  }
}