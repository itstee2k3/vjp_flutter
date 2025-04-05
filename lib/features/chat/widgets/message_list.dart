import 'package:flutter/material.dart';
import '../../../data/models/message.dart';
import 'image_message_bubble.dart';
import 'text_message_bubble.dart';

class MessageList extends StatefulWidget {
  final List<Message> messages;
  final String currentUserId;
  final ScrollController scrollController;
  final VoidCallback? onRetryImage;
  final Function(Message)? onRetryImageWithMessage;
  final bool hasMoreMessages;
  final bool isLoadingMore;
  final VoidCallback? onLoadMore;

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
        print('Overscroll update: amount=$overscrollAmount, progress=$progress, threshold=$_overscrollThreshold');

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
      print('Scroll end: shouldLoadMore=$_shouldLoadMore, hasMoreMessages=${widget.hasMoreMessages}, isLoadingMore=${widget.isLoadingMore}');

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
      const double textHeightEstimate = 60.0; // Adjust based on your text bubble height + padding
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

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: AnimatedOpacity(
                    opacity: _messageAnimations[index],
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    child: message.type == MessageType.image
                        ? ImageMessageBubble(
                            message: message,
                            isMe: isMe,
                            onRetry: widget.onRetryImage,
                            onRetryWithMessage: widget.onRetryImageWithMessage,
                          )
                        : TextMessageBubble(
                            message: message,
                            isMe: isMe,
                          ),
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