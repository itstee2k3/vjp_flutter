import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart'; // For date formatting
import '../../cubits/shared/chat_media_cubit.dart';
import '../../cubits/shared/chat_media_state.dart';
import '../../../../data/models/message.dart';
import '../../../../core/config/api_config.dart'; // For getFullImageUrl

// Define ChatType enum if not globally available (or import if it is)
// enum ChatType { personal, group }

class ChatMediaScreen extends StatelessWidget {
  final String chatIdString;
  final String chatTypeString; // Use String from router

  const ChatMediaScreen({
    Key? key,
    required this.chatIdString,
    required this.chatTypeString,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Determine ChatType from string
    // final chatType = chatTypeString == 'personal' ? ChatType.personal : ChatType.group;

    // Determine title based on type
    final title = 'Ảnh, file, link'; // Can customize later if needed

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        // Add actions like search, filter if needed
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Tìm kiếm',
            onPressed: () { /* TODO: Implement search */ },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            tooltip: 'Tùy chọn khác',
            onPressed: () { /* TODO: Implement more options */ },
          ),
        ],
      ),
      body: DefaultTabController(
        length: 4, // Number of tabs: Ảnh, File, Link, Tin nhắn thoại
        child: Column(
          children: [
            // Optional: Filter chips (like "Theo người gửi", "Video", "Theo thời gian")
            // Padding(
            //   padding: const EdgeInsets.all(8.0),
            //   child: Wrap(
            //     spacing: 8.0,
            //     children: [
            //       FilterChip(label: Text('Theo người gửi'), onSelected: (b){}),
            //       FilterChip(label: Text('Video'), onSelected: (b){}),
            //       FilterChip(label: Text('Theo thời gian'), onSelected: (b){}),
            //     ],
            //   ),
            // ),

            const TabBar(
              tabs: [
                Tab(text: 'Ảnh'),
                Tab(text: 'File'),
                Tab(text: 'Link'),
                Tab(text: 'Tin nhắn thoại'), // Voice messages
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  // Use the new _ImageGalleryTab widget
                  _ImageGalleryTab(),
                  // Placeholder for Files Tab
                  Center(child: Text('Nội dung File (ID: $chatIdString)')),
                  // Placeholder for Links Tab
                  Center(child: Text('Nội dung Link (ID: $chatIdString)')),
                  // Placeholder for Voice Messages Tab
                  Center(child: Text('Nội dung Tin nhắn thoại (ID: $chatIdString)')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Image Gallery Tab Widget ---

class _ImageGalleryTab extends StatefulWidget {
  @override
  State<_ImageGalleryTab> createState() => _ImageGalleryTabState();
}

class _ImageGalleryTabState extends State<_ImageGalleryTab> {
  // final ScrollController _scrollController = ScrollController(); // Remove ScrollController

  @override
  void initState() {
    super.initState();
    // _scrollController.addListener(_onScroll); // Remove listener
  }

  @override
  void dispose() {
    // _scrollController.removeListener(_onScroll); // Remove listener removal
    // _scrollController.dispose(); // Remove dispose
    super.dispose();
  }

  /* // Remove _onScroll and _isBottom logic
  void _onScroll() {
    if (_isBottom) {
      final cubit = context.read<ChatMediaCubit>();
      // Check hasMore and not already loading more before calling
      if (cubit.state.hasMore && !cubit.state.isLoadingMore) {
         cubit.loadMoreMedia();
      }
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    // Trigger slightly before reaching the absolute bottom
    return currentScroll >= (maxScroll * 0.9);
  }
  */

  @override
  Widget build(BuildContext context) {
    // Wrap the BlocBuilder with BlocListener
    return BlocListener<ChatMediaCubit, ChatMediaState>(
      listener: (context, state) {
        // If the state is successful and has more pages, trigger loading the next page
        if (state.status == ChatMediaStatus.success && state.hasMore && !state.isLoadingMore) {
           // Add a small delay to prevent potential rapid firing in some edge cases
           // and allow the UI to update before the next fetch starts.
           Future.delayed(const Duration(milliseconds: 100), () {
             // Check context is still mounted before calling read
             if (mounted) {
               context.read<ChatMediaCubit>().loadMoreMedia();
             }
           });
        }
      },
      child: BlocBuilder<ChatMediaCubit, ChatMediaState>(
        builder: (context, state) {
          // Initial Loading: Show indicator only if status is loading AND the list is truly empty (first load)
          if (state.status == ChatMediaStatus.loading && state.imageMessages.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          // Initial Failure: Show full error only if the first load failed and list is empty
          else if (state.status == ChatMediaStatus.failure && state.imageMessages.isEmpty) {
            return Center(child: Text('Lỗi tải ảnh: ${state.errorMessage ?? 'Không rõ'}'));
          }
          // Empty State: Show after a successful load (initial or later) finds nothing
          else if (state.status == ChatMediaStatus.success && state.imageMessages.isEmpty && !state.hasMore) { // Ensure hasMore is false for empty state
            return const Center(child: Text('Chưa có ảnh nào trong cuộc trò chuyện này.'));
          }
          // --- If we have images OR we are in the process of loading more ---
          else if (state.imageMessages.isNotEmpty || state.isLoadingMore || state.hasMore) {
             // Group images by date
             final groupedImages = _groupMessagesByDate(state.imageMessages); // Use imageMessages

             return ListView.builder(
               // controller: _scrollController, // Remove controller
               // Add 1 to item count for potential loading indicator at the bottom
               // Show indicator if loading more OR if successfully loaded but still has more to load automatically
               itemCount: groupedImages.length + ((state.isLoadingMore || state.hasMore) ? 1 : 0),
               itemBuilder: (context, index) {
                  // Check if this is the loading indicator item
                  final isLoadingIndicatorIndex = index == groupedImages.length;
                  if (isLoadingIndicatorIndex && (state.isLoadingMore || state.hasMore)) {
                    return _buildLoadingIndicator();
                  }
                  // Prevent index out of bounds if indicator logic is slightly off
                  if (index >= groupedImages.length) {
                    return const SizedBox.shrink(); // Should not happen, but safety first
                  }

                 // Regular date group item
                 final date = groupedImages.keys.elementAt(index);
                 final imagesForDate = groupedImages[date]!;
                 final formattedDate = DateFormat("d 'ngày' MM, yyyy", "vi_VN").format(date);

                 return Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     Padding(
                       padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                       child: Text(
                         formattedDate,
                         style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                       ),
                     ),
                     GridView.builder(
                       shrinkWrap: true, // Important inside ListView
                       physics: const NeverScrollableScrollPhysics(), // Disable GridView scrolling
                       gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                         crossAxisCount: 3, // Number of columns
                         crossAxisSpacing: 2.0, // Spacing between columns
                         mainAxisSpacing: 2.0, // Spacing between rows
                       ),
                       itemCount: imagesForDate.length,
                       itemBuilder: (context, imgIndex) {
                         final message = imagesForDate[imgIndex];
                         final imageUrl = ApiConfig.getFullImageUrl(message.imageUrl!);

                         return GestureDetector(
                           onTap: () {
                             // TODO: Implement image viewer (e.g., show full screen)
                             print("Tapped image: $imageUrl");
                           },
                           child: Image.network(
                             imageUrl,
                             fit: BoxFit.cover,
                             loadingBuilder: (context, child, loadingProgress) {
                               if (loadingProgress == null) return child;
                               return Container(color: Colors.grey[200]);
                             },
                             errorBuilder: (context, error, stackTrace) {
                               return Container(
                                  color: Colors.grey[300],
                                  child: Icon(Icons.broken_image, color: Colors.grey[600]),
                               );
                             },
                           ),
                         );
                       },
                     ),
                     const SizedBox(height: 16), // Spacing after grid
                   ],
                 );
               },
             );
          }
          // Fallback (Should ideally not be reached with the logic above)
          else {
             return const Center(child: Text('Trạng thái không xác định'));
          }
        },
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16.0),
      child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
    );
  }

  // Helper to group messages by date (ignoring time)
  Map<DateTime, List<Message>> _groupMessagesByDate(List<Message> messages) {
    final Map<DateTime, List<Message>> grouped = {};
    for (final message in messages) {
      // Ensure message.imageUrl is not null or empty before proceeding
      if (message.imageUrl != null && message.imageUrl!.isNotEmpty) {
        final date = DateTime(message.sentAt.year, message.sentAt.month, message.sentAt.day);
        if (grouped[date] == null) {
          grouped[date] = [];
        }
        grouped[date]!.add(message);
      }
    }
    // Sort messages within each date if needed (newest first)
    grouped.forEach((key, value) {
      value.sort((a, b) => b.sentAt.compareTo(a.sentAt));
    });
     // Sort the dates themselves (most recent date first)
    final sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));
    final sortedGrouped = { for (var key in sortedKeys) key : grouped[key]! };
    return sortedGrouped;
  }
} 