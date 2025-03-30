import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../data/models/message.dart';
import '../../../core/config/api_config.dart';
import 'message_time.dart';

class ImageMessageBubble extends StatelessWidget {
  final Message message;
  final bool isMe;
  final VoidCallback? onRetry;

  const ImageMessageBubble({
    Key? key,
    required this.message,
    required this.isMe,
    this.onRetry,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget imageContent;

    if (message.isSending) {
      imageContent = _buildSendingState();
    } else if (message.isError) {
      imageContent = _buildErrorState();
    } else if (message.imageUrl != null) {
      imageContent = _buildImageContent(context);
    } else {
      imageContent = _buildUnknownState();
    }

    return Container(
      margin: EdgeInsets.symmetric(vertical: 4),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          padding: EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isMe ? Colors.blue : Colors.grey[200],
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              imageContent,
              const SizedBox(height: 4),
              MessageTime(time: message.sentAt, isMe: isMe),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSendingState() {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        color: isMe ? Colors.blue.withOpacity(0.3) : Colors.grey[300],
        borderRadius: BorderRadius.circular(8),
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

  Widget _buildErrorState() {
    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: Colors.red[100],
        borderRadius: BorderRadius.circular(8),
      ),
      padding: EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.error, color: Colors.red),
              SizedBox(width: 8),
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
          if (onRetry != null) ...[
            SizedBox(height: 8),
            TextButton(
              onPressed: onRetry,
              child: Text('Thử lại'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildImageContent(BuildContext context) {
    final uniqueKey = Key('image_${message.id}_${message.imageUrl}_${DateTime.now().millisecondsSinceEpoch}');
    final uniqueCacheKey = 'image_${message.id}_${message.imageUrl}';

    return GestureDetector(
      onTap: () => _showFullScreenImage(context),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
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
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
              errorWidget: (context, url, error) => GestureDetector(
                onTap: () {
                  CachedNetworkImage.evictFromCache(url);
                  if (onRetry != null) {
                    onRetry!();
                  }
                },
                child: Container(
                  width: 200,
                  height: 200,
                  color: isMe ? Colors.blue.withOpacity(0.3) : Colors.grey[300],
                  child: Center(
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
              fadeInDuration: Duration(milliseconds: 200),
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

  Widget _buildUnknownState() {
    return GestureDetector(
      onTap: onRetry,
      child: Container(
        width: 200,
        height: 100,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(8),
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
              if (onRetry != null) ...[
                SizedBox(height: 8),
                TextButton(
                  onPressed: onRetry,
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