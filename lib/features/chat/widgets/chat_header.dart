import 'package:flutter/material.dart';
import '../../../core/config/api_config.dart';
import 'package:go_router/go_router.dart';

class ChatHeader extends StatelessWidget {
  final String title;
  final String? avatarUrl;
  final VoidCallback? onInfoPressed;
  final VoidCallback onRefreshPressed;
  final bool isGroup;

  const ChatHeader({
    Key? key,
    required this.title,
    this.avatarUrl,
    this.onInfoPressed,
    required this.onRefreshPressed,
    this.isGroup = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    print('🎯 ChatHeader build:');
    print('Title: $title');
    print('Avatar URL: $avatarUrl');
    print('Is group: $isGroup');
    
    String? processedAvatarUrl;
    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      if (avatarUrl!.startsWith('/')) {
        processedAvatarUrl = '${ApiConfig.baseUrl}$avatarUrl';
      } else {
        processedAvatarUrl = avatarUrl;
      }
      // Add cache busting parameter
      processedAvatarUrl = '$processedAvatarUrl?t=${DateTime.now().millisecondsSinceEpoch}';
    }
        
    print('Processed avatar URL: $processedAvatarUrl');
    
    return AppBar(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black87,
      elevation: 1,
      shadowColor: Colors.grey[200],
      iconTheme: const IconThemeData(color: Colors.black87),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => context.pop(),
      ),
      title: Row(
        children: [
          CircleAvatar(
            key: ValueKey('chat-header-avatar-${avatarUrl ?? "default"}'),
            radius: 20,
            backgroundColor: Colors.grey[200],
            child: ClipOval(
               child: processedAvatarUrl != null
                 ? Image.network(
                     processedAvatarUrl,
                     fit: BoxFit.cover,
                     width: 40,
                     height: 40,
                     errorBuilder: (context, error, stackTrace) {
                        print('❌ Error loading avatar in ChatHeader (Image.network):');
                        print('Processed URL: $processedAvatarUrl');
                        print('Error: $error');
                        return Image.asset(
                           isGroup 
                             ? ApiConfig.defaultGroupAvatar 
                             : ApiConfig.defaultUserAvatar,
                           fit: BoxFit.cover,
                           width: 40,
                           height: 40,
                        );
                     },
                   )
                 : Image.asset(
                      isGroup 
                        ? ApiConfig.defaultGroupAvatar 
                        : ApiConfig.defaultUserAvatar,
                      fit: BoxFit.cover,
                      width: 40,
                      height: 40,
                 ),
            )
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        // IconButton(
        //   icon: const Icon(Icons.refresh),
        //   onPressed: onRefreshPressed,
        // ),
        if (isGroup)
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'Thông tin nhóm',
            onPressed: onInfoPressed,
          ),
      ],
    );
  }
}