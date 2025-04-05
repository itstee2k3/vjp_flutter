import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../data/models/message.dart';
import '../../../core/config/api_config.dart';
import 'message_time.dart';
import 'message_list.dart';

class ImageMessageBubble extends StatelessWidget {
  final Message message;
  final bool isMe;
  final VoidCallback? onRetry;
  final Function(Message)? onRetryWithMessage;
  final BubblePosition bubblePosition;
  final bool showSenderInfo;
  final Map<String, dynamic>? senderInfo; // Thông tin người gửi (fullName, avatarUrl)

  const ImageMessageBubble({
    Key? key,
    required this.message,
    required this.isMe,
    this.onRetry,
    this.onRetryWithMessage,
    required this.bubblePosition,
    this.showSenderInfo = false,
    this.senderInfo,
  }) : super(key: key);

  // Helper method to call the appropriate retry callback
  void _handleRetry() {
    if (onRetryWithMessage != null) {
      onRetryWithMessage!(message);
    } else if (onRetry != null) {
      onRetry!();
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget imageContent;

    const Radius messageRadius = Radius.circular(12);
    const Radius sharpRadius = Radius.circular(4);

    BorderRadius containerBorderRadius;
    BorderRadius imageBorderRadius;

    switch (bubblePosition) {
      case BubblePosition.single:
        containerBorderRadius = BorderRadius.all(messageRadius);
        imageBorderRadius = BorderRadius.all(messageRadius - Radius.circular(4));
        break;
      case BubblePosition.first:
        containerBorderRadius = isMe
            ? const BorderRadius.only(topLeft: messageRadius, topRight: messageRadius, bottomLeft: messageRadius, bottomRight: sharpRadius)
            : const BorderRadius.only(topLeft: messageRadius, topRight: messageRadius, bottomLeft: sharpRadius, bottomRight: messageRadius);
        imageBorderRadius = isMe
            ? const BorderRadius.only(topLeft: messageRadius, topRight: messageRadius, bottomLeft: messageRadius, bottomRight: Radius.zero)
            : const BorderRadius.only(topLeft: messageRadius, topRight: messageRadius, bottomLeft: Radius.zero, bottomRight: messageRadius);
        break;
      case BubblePosition.middle:
        containerBorderRadius = isMe
            ? const BorderRadius.only(topLeft: messageRadius, topRight: sharpRadius, bottomLeft: messageRadius, bottomRight: sharpRadius)
            : const BorderRadius.only(topLeft: sharpRadius, topRight: messageRadius, bottomLeft: sharpRadius, bottomRight: messageRadius);
        imageBorderRadius = isMe
            ? const BorderRadius.only(topLeft: messageRadius, topRight: Radius.zero, bottomLeft: messageRadius, bottomRight: Radius.zero)
            : const BorderRadius.only(topLeft: Radius.zero, topRight: messageRadius, bottomLeft: Radius.zero, bottomRight: messageRadius);
        break;
      case BubblePosition.last:
        containerBorderRadius = isMe
            ? const BorderRadius.only(topLeft: messageRadius, topRight: sharpRadius, bottomLeft: messageRadius, bottomRight: messageRadius)
            : const BorderRadius.only(topLeft: sharpRadius, topRight: messageRadius, bottomLeft: messageRadius, bottomRight: messageRadius);
        imageBorderRadius = isMe
            ? const BorderRadius.only(topLeft: messageRadius, topRight: Radius.zero, bottomLeft: messageRadius, bottomRight: messageRadius)
            : const BorderRadius.only(topLeft: Radius.zero, topRight: messageRadius, bottomLeft: messageRadius, bottomRight: messageRadius);
        break;
    }

    if (message.isSending) {
      imageContent = _buildSendingState(containerBorderRadius);
    } else if (message.isError) {
      imageContent = _buildErrorState(containerBorderRadius);
    } else if (message.imageUrl != null) {
      imageContent = _buildImageContent(context, imageBorderRadius);
    } else {
      imageContent = _buildUnknownState(containerBorderRadius);
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 0),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // Hiển thị tên người gửi ở chat nhóm khi showSenderInfo = true
            if (showSenderInfo && senderInfo != null && (bubblePosition == BubblePosition.first || bubblePosition == BubblePosition.single))
              Padding(
                padding: const EdgeInsets.only(left: 8.0, bottom: 4.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (senderInfo!['avatarUrl'] != null)
                      CircleAvatar(
                        radius: 10,
                        backgroundImage: NetworkImage(senderInfo!['avatarUrl']),
                      )
                    else
                      CircleAvatar(
                        radius: 10,
                        backgroundImage: AssetImage("assets/avatar_default/avatar_default.png") as ImageProvider,
                      ),
                    const SizedBox(width: 4),
                    Text(
                      senderInfo!['fullName'] ?? 'Unknown',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            // Ảnh tin nhắn
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: isMe ? Colors.blue : Colors.grey[200],
                borderRadius: containerBorderRadius,
              ),
              child: imageContent,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSendingState(BorderRadius borderRadius) {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        color: isMe ? Colors.blue.withOpacity(0.3) : Colors.grey[300],
        borderRadius: borderRadius,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                isMe ? Colors.white : Colors.blue,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Đang gửi...',
              style: TextStyle(
                color: isMe ? Colors.white : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BorderRadius borderRadius) {
    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: Colors.red[100],
        borderRadius: borderRadius,
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.error, color: Colors.red),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message.content,
                  style: TextStyle(
                    color: Colors.red[800],
                  ),
                ),
              ),
            ],
          ),
          if (onRetry != null || onRetryWithMessage != null) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: _handleRetry,
              child: const Text('Thử lại'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildImageContent(BuildContext context, BorderRadius imageBorderRadius) {
    final uniqueKey = Key('image_${message.id}_${message.imageUrl}_${DateTime.now().millisecondsSinceEpoch}');
    final uniqueCacheKey = 'image_${message.id}_${message.imageUrl}';

    return GestureDetector(
      onTap: () => _showFullScreenImage(context),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: imageBorderRadius,
            child: CachedNetworkImage(
              imageUrl: ApiConfig.getFullImageUrl(message.imageUrl),
              width: 200,
              height: 200,
              fit: BoxFit.cover,
              cacheKey: uniqueCacheKey,
              placeholder: (context, url) => Container(
                width: 200,
                height: 200,
                color: isMe ? Colors.blue.withOpacity(0.3) : Colors.grey[300],
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
              errorWidget: (context, url, error) => GestureDetector(
                onTap: () {
                  CachedNetworkImage.evictFromCache(url);
                  _handleRetry();
                },
                child: Container(
                  width: 200,
                  height: 200,
                  color: isMe ? Colors.blue.withOpacity(0.3) : Colors.grey[300],
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error, color: Colors.red),
                        SizedBox(height: 4),
                        Text(
                          'Lỗi tải ảnh - Nhấn để thử lại',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              key: uniqueKey,
              memCacheWidth: 800,
              memCacheHeight: 800,
              maxWidthDiskCache: 800,
              fadeOutDuration: Duration.zero,
              fadeInDuration: const Duration(milliseconds: 200),
              useOldImageOnUrlChange: true,
            ),
          ),
          if (message.content.isNotEmpty && message.content != '[Hình ảnh]')
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                message.content,
                style: TextStyle(
                  color: isMe ? Colors.white : Colors.black,
                  fontSize: 14,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUnknownState(BorderRadius borderRadius) {
    return GestureDetector(
      onTap: _handleRetry,
      child: Container(
        width: 200,
        height: 100,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: borderRadius,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.image_not_supported, color: Colors.grey[600]),
              SizedBox(height: 4),
              Text(
                'Không thể hiển thị hình ảnh',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey[800]),
              ),
              if (onRetry != null || onRetryWithMessage != null) ...[
                SizedBox(height: 8),
                TextButton(
                  onPressed: _handleRetry,
                  child: Text('Tải lại'),
                  style: TextButton.styleFrom(
                    minimumSize: Size(100, 30),
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showFullScreenImage(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: IconThemeData(color: Colors.white),
            actions: [
              IconButton(
                icon: Icon(Icons.refresh),
                onPressed: () {
                  final url = ApiConfig.getFullImageUrl(message.imageUrl);
                  CachedNetworkImage.evictFromCache(url);
                  Navigator.pop(context);
                  Future.delayed(Duration(milliseconds: 100), () {
                    _showFullScreenImage(context);
                  });
                },
              ),
            ],
          ),
          backgroundColor: Colors.black,
          body: Center(
            child: InteractiveViewer(
              child: Hero(
                tag: 'image_${message.id}',
                child: CachedNetworkImage(
                  imageUrl: ApiConfig.getFullImageUrl(message.imageUrl),
                  fit: BoxFit.contain,
                  placeholder: (context, url) => Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  errorWidget: (context, url, error) => Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, color: Colors.red, size: 48),
                      SizedBox(height: 8),
                      Text(
                        'Không thể tải hình ảnh',
                        style: TextStyle(color: Colors.white),
                      ),
                      SizedBox(height: 8),
                      Text(
                        error.toString(),
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          CachedNetworkImage.evictFromCache(url);
                          Navigator.pop(context);
                          Future.delayed(Duration(milliseconds: 100), () {
                            _showFullScreenImage(context);
                          });
                        },
                        child: Text('Tải lại'),
                      ),
                    ],
                  ),
                  cacheKey: 'fullscreen_${message.id}_${message.imageUrl}',
                  maxWidthDiskCache: 1200,
                  memCacheWidth: 1200,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}